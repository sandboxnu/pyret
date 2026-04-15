/** @satisfies {PyretModule} */
({
    requires: [],
    nativeRequires: [
        'pyret-base/js/js-numbers',
    ],
    provides: {
        values: {},
        types: {}
    },
    theModule: function(RUNTIME, NAMESPACE, uri, jsnums) {
        /**
         * Euclidean distance between two points
         * @param {[number, number]} xs - a pair of x-values
         * @param {[number, number]} ys - a corresponding pair of y-values
         * @returns {number} - the loss for the interval
         */
        function defaultLoss(xs, ys) {
            const dx = xs[1] - xs[0];
            const dy = ys[1] - ys[0];
            return Math.hypot(dx, dy);
        }

        /**
         * Distance between two x-values
         * @param {[number, number]} xs - a pair of x-values
         * @param {[number, number]} ys - unused (only passed in for consistency with other loss functions)
         * @returns {number} - the loss for the interval
         */
        function uniformLoss(xs, ys) {
            return xs[1] - xs[0];
        }

        /**
         * Penalizes y-values close to 0
         * Implementation of abs_min_log_loss from adaptive (min not required for scalars)
         * @param {[number, number]} xs - a pair of x-values
         * @param {[number, number]} ys - a corresponding pair of y-values
         * @returns {number} - the loss for the interval
         */
        function absLogLoss(xs, ys) {
            // bound the transformed y-value in case y = 0
            const lowerBound = -1e12;
            const ysLog = ys.map(y => Math.max(lowerBound, Math.log(Math.abs(y))));
            return defaultLoss(xs, (/** @type {[number, number]} */ (ysLog)));
        }

        /** @typedef {{x: number[], y: number[]}} Foo */

        /**
         * Flow:
         * 1. Initialize data
         * 2. Compute losses
         * 3. Identify interval with max loss
         * 4. Split interval in half
         * 5. Repeat steps 2-4 until stopping condition
         */
        class AdaptiveSampler {
            /**
             * @param {PyretFunction} func - function to plot
             * @param {number} xMinValue - min x-value
             * @param {number} xMaxValue - max x-value
             * @param {Function} lossFunction - loss function
             * @param {number} numSamples - max number of data points to sample
             */
            constructor(func, xMinValue, xMaxValue, lossFunction, numSamples) {
                // format: [[x1, x2, loss]]
                this.lossManager = (/** @type {[number, number, number][]} */ ([]));
                // format: {x1: y1, x2: y2, ...}
                this.data = new Map();
                this.func = func;
                this.xMinValue = xMinValue;
                this.xMaxValue = xMaxValue;
                this.lossFunction = lossFunction;
                this.numSamples = numSamples;
                this.pending = (/** @type {[number, number][]} */ ([]));
            }
            // runs the function more safely (handles zero division and Pyret nums)
            // FIX: janky error handling
            /**
             * @param {Number} input
             * @returns {Foo}
             */
            runFuncSafe(input) {
                let x = input;
                return RUNTIME.safeCall(
                    () => RUNTIME.execThunk(RUNTIME.makeFunction(() => this.func.app(x))),
                    (result) => {
                        if (result.$name === "left") {
                            const output = RUNTIME.getField(result, "v");
                            const y = typeof output == "number" ? output : jsnums.toFixnum(output);
                            return {"x": [x], "y": [y]};
                        } else {
                            return null;
                        }
                    },
                    "runFuncSafe"
                );
            };

            runFunc(input, offset = 1e-6) {
                let x = input;
                console.log("[runFunc] calling func with x =", x);
                return RUNTIME.safeCall(
                    () => this.runFuncSafe(x),
                    (result) => {
                        if (result !== null) {
                            console.log("[runFunc] success: x =", x, "y =", result.y[0]);
                            return result;
                        }
                        console.log("[runFunc] error for x =", x, "trying offsets");
                        const x1 = x - offset;
                        const x2 = x + offset;
                        return RUNTIME.safeCall(
                            () => this.runFunc(x1),
                            (r1) => RUNTIME.safeCall(
                                () => this.runFunc(x2),
                                (r2) => ({"x": [x1, x2], "y": [r1.y[0], r2.y[0]]}),
                                "runFunc-offset-2"
                            ),
                            "runFunc-offset-1"
                        );
                    },
                    "runFunc"
                );
            };

            // initialize data by computing f(x) for endpoints
            initData() {
                console.log("[initData] starting with xMin =", this.xMinValue, "xMax =", this.xMaxValue);
                return RUNTIME.safeCall(
                    () => this.runFunc(this.xMinValue),
                    (lower) => {
                        console.log("[initData] lower result:", lower);
                        return RUNTIME.safeCall(
                        () => this.runFunc(this.xMaxValue),
                        (upper) => {
                            console.log("[initData] upper result:", upper);
                            lower.x.forEach((xi, i) => this.data.set(xi, lower.y[i]));
                            upper.x.forEach((xi, i) => this.data.set(xi, upper.y[i]));
                            // adds lower x1 and upper x2 (outer bounds) if there is more than one x returned
                            this.pending.push([lower.x[0], (/** @type {number} */ (upper.x.at(-1)))]);
                            console.log("[initData] done, data size =", this.data.size, "pending =", this.pending);
                        },
                        "initData-upper"
                    );},
                    "initData-lower"
                );
            };

            // compute loss for each interval in pending
            // FIX: janky error handling
            computeLosses() {
                while (this.pending.length > 0) {
                    const xs = /** @type {[number, number]} */ (this.pending.pop());
                    const ys = [this.data.get(xs[0]), this.data.get(xs[1])];
                    if (ys.includes(undefined)) continue;
                    const loss = this.lossFunction(xs, ys);
                    this.lossManager.push([...xs, loss]);
                }
            };

            // get the interval with the max loss
            // TODO: handling multiple intervals with the same max loss (particularly important for uniform loss)
            getMaxLoss() {
                let maxLoss = -Infinity;
                let maxInterval = null;
                let maxIndex = null;

                for (let i = 0; i < this.lossManager.length; i++) {
                    const item = this.lossManager[i];
                    if (item[2] > maxLoss) {
                        maxLoss = item[2];
                        maxInterval = item.slice(0, 2);
                        maxIndex = i;
                    }
                }
                return { maxInterval, maxIndex };
            };

            // split an interval in half, compute y-value of the midpoint, and add new intervals to pending
            /**
             * @param {number[]} maxInterval 
             * @param {number} maxIndex 
             */
            splitInterval(maxInterval, maxIndex) {
                const [l, r] = maxInterval;
                const m = (l + r) / 2;
                return RUNTIME.safeCall(
                    () => this.runFunc(m),
                    (coord) => {
                        coord.x.forEach((xi, i) => this.data.set(xi, coord.y[i]));
                        this.lossManager.splice(maxIndex, 1);
                        this.pending.push([l, coord.x[0]], [/** @type {number} */ (coord.x.at(-1)), r]);
                    },
                    "splitInterval"
                );
            };

            // runs the adaptive sampler
            // TODO: adding different stopping conditions (e.g. error threshold)
            runner() {
                console.log("[runner] starting, numSamples =", this.numSamples);
                /** @returns {PyretNothing} */
                const iterate = () => {
                    console.log("[iterate] data size =", this.data.size, "/ target =", this.numSamples);
                    if (this.data.size >= this.numSamples) {
                        console.log("[iterate] done, final data size =", this.data.size);
                        return RUNTIME.nothing;
                    }
                    const { maxInterval, maxIndex } = this.getMaxLoss();
                    if (maxInterval === null || maxIndex === null) {
                        console.log("[iterate] no intervals found in lossManager, stopping early");
                        return RUNTIME.nothing;
                    }
                    console.log("[iterate] splitting interval", maxInterval, "at index", maxIndex);
                    return RUNTIME.safeCall(
                        () => this.splitInterval(maxInterval, maxIndex),
                        () => {
                            this.computeLosses();
                            return iterate();
                        },
                        "runner-iterate"
                    );
                };
                return RUNTIME.safeCall(
                    () => this.initData(),
                    () => {
                        console.log("[runner] initData complete, computing initial losses");
                        this.computeLosses();
                        return iterate();
                    },
                    "runner-init"
                );
            };

        }
    
    return RUNTIME.makeModuleReturn({}, {}, {
        defaultLoss: defaultLoss,
        uniformLoss: uniformLoss,
        absLogLoss: absLogLoss,
        AdaptiveSampler: AdaptiveSampler
    });
    }
})