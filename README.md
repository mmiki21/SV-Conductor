#  ![web_logo](https://user-images.githubusercontent.com/94343931/209506574-90ab30ef-ef08-477d-bd31-dc42ffbb7bdb.JPG)


# Overview
SV-Conductor is the SV-callers(structural variant callers) docker container which include Manta, Delly, Gridss, Svaba, Tiddit, Pindel, Imsindel, Mobster, ScanITD. Run SV-Conductor, then 9 SV callers are sequentially executed. Output VCF files from all the SV callers are merged into one VCF file by Viola-SV.

# Installation
Install Docker if it is not installed and after install it, docker build by dockerfile.


# Usage
Specify the reference genome fasta, tumor bam, normal bam, and working directory in the configuration file.
Then run the script.sh.
