# ENSVAR-4591

This branch is based on Nuno branch [ENSVAR-4550](https://github.com/nuno-agostinho/ENSVAR-4550) to make other benchmark.

## How to run the script

Install [Nextflow](https://nextflow.io) and run:

* I have used [miniconda3](https://conda.io/miniconda.html) to install.

```
bsub nextflow run main.nf
```

To change the number of runs of each test:

```
bsub nextflow run main.nf --repeat 3
```

To override the tested flags (notice that there needs to be a space for
Nextflow to correctly interpret the parameter as a string and not as an
argument for itself):

```
bsub nextflow run main.nf --flags "--regulatory "
```
