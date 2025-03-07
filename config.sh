#sourceme

# point to MG dir, which is usually where Pythia and Delphes live.
MG_DIR=/data7/atlas/cshimmin/zplite/MG5_aMC

### The following variables must be exported.
### Configure them to match your system.

# Point to the /src directory of the pythia distribution (should
# be compatible with the version distributed by MG).
export PYTHIA_DIR=${MG_DIR}/pythia-pgs/src

# Point to the root Delphes directory (should be compatible with the
# version distributed by MG).
export DELPHES_DIR=${MG_DIR}/Delphes
