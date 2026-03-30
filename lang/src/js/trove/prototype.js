/**
 * flow:
 * 1. take in a function
 * 2. apply f(x) to each x (abstracted and will be done in Pyret)
 * 3. compute loss over each interval
 * 4. split interval w/ highest loss in half
 * 5. recompute losses
 * Stopping condition: threshold, numSamples
 * To do: how to decide which loss function for a given f
 */

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

function AdaptiveSampler(f, xMinValue, xMaxValue, lossFunction, numSamples) {
    this.lossManager = [];
    this.data = new Map();
    this.f = f;
    this.xMinValue = xMinValue;
    this.xMaxValue = xMaxValue;
    this.lossFunction = lossFunction;
    this.numSamples = numSamples;
    this.pending = [];

    // initialize data by uniformly computing f(x) across the domain
    this.initData = function() {
        for (let i = xMinValue; i <= xMaxValue; i++) {
            this.data.set(i, this.f(i));
            if (i < xMaxValue) {
                this.pending.push([i, i + 1]);
            }
        }
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
        this.data.set(m, this.f(m));
        this.lossManager.splice(maxIndex, 1);
        this.pending.push([l, m], [m, r]);
    };

    this.runner = function() {
        this.initData();
        this.computeLosses();
        while (this.data.size < this.numSamples) {
            const maxLoss = this.getMaxLoss()
            this.splitInterval(maxLoss.maxInterval, maxLoss.maxIndex)
            this.computeLosses()
        }
    };
}

// testing
const learner = new AdaptiveSampler(x => x**2, 2, 5, defaultLoss, 10);
// learner.initData();
// learner.computeLosses();
// console.log(learner.data, learner.pending, learner.lossManager);
// const result = learner.getMaxLoss();
// learner.splitInterval(result.maxInterval, result.maxIndex);
// console.log(learner.data, learner.pending, learner.lossManager);
learner.runner()
console.log(learner.data, learner.pending, learner.lossManager);