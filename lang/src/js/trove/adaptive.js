({
    requires: [],
    nativeRequires: [],
    provides: {
        values: {},
        types: {}
    },
    theModule: function(RUNTIME, NAMESPACE, uri) {
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
            return defaultLoss(xs, ysLog);
        }

        /**
         * Flow:
         * 1. Initialize data
         * 2. Compute losses
         * 3. Identify interval with max loss
         * 4. Split interval in half
         * 5. Repeat steps 2-4 until stopping condition
         * @param {Function} func - function to plot
         * @param {number} xMinValue - min x-value
         * @param {number} xMaxValue - max x-value
         * @param {Function} lossFunction - loss function
         * @param {number} numSamples - max number of data points to sample
         */
        function AdaptiveSampler(func, xMinValue, xMaxValue, lossFunction, numSamples) {
            this.lossManager = [];
            this.data = new Map();
            this.func = func;
            this.xMinValue = xMinValue;
            this.xMaxValue = xMaxValue;
            this.lossFunction = lossFunction;
            this.numSamples = numSamples;
            this.pending = [];

            // initialize data by computing f(x) for endpoints
            this.initData = function() {
                this.data.set(xMinValue, this.func.app(xMinValue));
                this.data.set(xMaxValue, this.func.app(xMaxValue));
                this.pending.push([xMinValue, xMaxValue]);
            };

            // compute loss for each interval in pending
            this.computeLosses = function() {
                while (this.pending.length > 0) {
                    const xs = this.pending.pop();
                    const ys = [this.data.get(xs[0]), this.data.get(xs[1])]
                    const loss = this.lossFunction(xs, ys)
                    this.lossManager.push([...xs, loss])
                }
            };

            // get the interval with the max loss
            // TODO: handling multiple intervals with the same max loss (particularly important for uniform loss)
            this.getMaxLoss = function() {
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
            this.splitInterval = function(maxInterval, maxIndex) {
                const [l, r] = maxInterval;
                const m = (l + r) / 2;
                this.data.set(m, this.func.app(m));
                this.lossManager.splice(maxIndex, 1);
                this.pending.push([l, m], [m, r]);
            };

            // runs the adaptive sampler
            // TODO: adding different stopping conditions
            this.runner = function() {
                this.initData();
                this.computeLosses();
                while (this.data.size < 10) {
                    const maxLoss = this.getMaxLoss()
                    this.splitInterval(maxLoss.maxInterval, maxLoss.maxIndex)
                    this.computeLosses()
                }
            };
        }

    var internal = {
        defaultLoss: defaultLoss,
        uniformLoss: uniformLoss,
        absLogLoss: absLogLoss,
        AdaptiveSampler: AdaptiveSampler
    };
    
    return RUNTIME.makeModuleReturn({}, {}, internal);
    }
})