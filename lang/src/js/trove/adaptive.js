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
            runFunc(input, offset = 1e-6) {
                let x = input;
                try {
                    // const y = RUNTIME.safeCall(() => {
                    //     return this.func.app(x);
                    // }, (output) => {
                    //     return typeof(output) == "number" ? output : jsnums.toFixnum(output)
                    // }, "runFunc")
                    const output = this.func.app(x);
                    const y = typeof (output) == "number" ? output : jsnums.toFixnum(output);
                    return { "x": [x], "y": [y] };
                } catch (e) {
                    if ((/** @type {ABI.FailureResult} */ (e))?.exn?.dict?.message?.includes("division by zero")) {
                        const x1 = x - offset;
                        const x2 = x + offset;

                        // FIX: recursive calls are probably not the best option
                        const y1 = this.runFunc(x1).y[0];
                        const y2 = this.runFunc(x2).y[0];

                        // (x1, y1) offset to the left of x
                        // (x2, y2) offset to the right of x
                        return { "x": [x1, x2], "y": [y1, y2] };
                    }
                    else {
                        throw e;
                    }
                }
            };

            // initialize data by computing f(x) for endpoints
            initData() {
                const lower = this.runFunc(this.xMinValue);
                const upper = this.runFunc(this.xMaxValue);

                lower.x.forEach((xi, i) => this.data.set(xi, lower.y[i]));
                upper.x.forEach((xi, i) => this.data.set(xi, upper.y[i]));

                // adds lower x1 and upper x2 (outer bounds) if there is more than one x returned
                this.pending.push([lower.x[0], (/** @type {number} */ (upper.x.at(-1)))]);
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
                const coord = this.runFunc(m);
                coord.x.forEach((xi, i) => this.data.set(xi, coord.y[i]));
                this.lossManager.splice(maxIndex, 1);
                this.pending.push([l, coord.x[0]], [/** @type {number} */ (coord.x.at(-1)), r]);
            };

            // runs the adaptive sampler
            // TODO: adding different stopping conditions (e.g. error threshold)
            runner() {
                this.initData();
                this.computeLosses();
                while (this.data.size < this.numSamples) {
                    console.log(this.data);
                    const maxLoss = this.getMaxLoss();
                    this.splitInterval(maxLoss.maxInterval, maxLoss.maxIndex);
                    this.computeLosses();
                }
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