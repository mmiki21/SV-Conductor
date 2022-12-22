#!/bin/sh

#file
ref="(path to reference file)"
normal="(path to normal bam)"
tumor="(path to tumor bam)"
out_dir="(path to output directory)"
mount_dir="(mountdirectory)"
sv_conductor="(docker name)"

#eval "mkdir $out_dir"

#manta
#manta_out_dir
manta_out_dir="manta_out"
eval "mkdir $out_dir/$manta_out_dir"
#config
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c '/opt/conda/pkgs/manta-1.6.0-h9ee0642_2/bin/configManta.py --normalBam=$normal --tumorBam=$tumor --referenceFasta=$ref --runDir=$out_dir/$manta_out_dir'"
#run
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c '$out_dir/$manta_out_dir/runWorkflow.py -m local -j 20 --memGb=20'"

#delly
#delly_out_dir
delly_out_dir="delly_out"
eval "mkdir $out_dir/$delly_out_dir"
#run
eval "docker run --rm -itv $mount_dir $sv_conductor delly call -o $out_dir/$delly_out_dir/(delly_out.bcf) -g $ref $tumor $normal"
#bcftools
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'bcftools view -Ov $out_dir/$delly_out_dir/(delly_out.bcf) -o $out_dir/$delly_out_dir/(delly_out.vcf)'"

#gridss
gridss_out_dir="gridss_out"
ref_genome_version="38"
eval "mkdir $out_dir/$gridss_out_dir"
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'cd $out_dir/$gridss_out_dir; gridss -r $ref -o $out_dir/$gridss_out_dir/(gridss_out.vcf) $normal $tumor --labels normal,tumor --threads 20'"
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'java -jar /opt/gridss/gripss_v2.3.2.jar -sample tumor -reference normal -ref_genome_version $ref_genome_version -ref_genome $ref -pon_sgl_file /38/gridss_pon_single_breakend.bed -pon_sv_file /38/gridss_pon_breakpoint.bedpe -vcf $out_dir/$gridss_out_dir/(gridss_out.vcf) -output_dir $out_dir/$gridss_out_dir'"

#tiddit
#tiddit_out_dir
tiddit_out_dir="tiddit_out"
#tumor
cmd_tumor='grep -E "#|PASS" tumor.vcf'
tiddit_tumor_out='(tumor_pass.vcf)'
eval "mkdir $out_dir/$tiddit_out_dir"
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'cd $out_dir/$tiddit_out_dir; tiddit --sv --p_ratio 0.10 --bam $tumor -o tumor --ref $ref --threads 20; $cmd_tumor > $tiddit_tumor_out'"
#normal
cmd_normal='grep -E "#|PASS" normal.vcf'
tiddit_normal_out='(normal_pass.vcf)'
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'cd $out_dir/$tiddit_out_dir; tiddit --sv --bam $normal -o normal --ref $ref --threads 20; $cmd_normal > $tiddit_normal_out'"
#svdb
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'cd $out_dir/$tiddit_out_dir; svdb --merge --vcf $tiddit_tumor_out $tiddit_normal_out --bnd_distance 500 --overlap 0.6 > (tiddit_tumor_normal.vcf)'"

#svaba
svaba_out_dir="svaba_out"
eval "mkdir $out_dir/$svaba_out_dir"
#eval "bwa index $ref"
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'cd $out_dir/$svaba_out_dir; svaba run -t $tumor -n $normal -G $ref -p 20'"

#scanitd
scanitd_out_dir="scanitd_out"
eval "mkdir $out_dir/$scanitd_out_dir"
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'python3 /opt/ScanITD/ScanITD.py -i $tumor -r $ref -o $out_dir/$scanitd_out_dir/(ScanITD_out.vcf)'"

#mobster
mobster_out_dir="mobster_out"
eval "mkdir $out_dir/$mobster_out_dir"
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'cd $out_dir/$mobster_out_dir; mobster -properties (mobster.properties file) -in $tumor -out (mobster_out name) -sn tumor"
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'cd $out_dir/$mobster_out_dir; mobster-to-vcf -file mobster_out_predictions.txt -out (mobster_out.vcf)"

#imsindel
imsindel_out_dir="imsindel_out"
eval "mkdir $out_dir/$imsindel_out_dir"
#chr1-22
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22
do
   eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'cd $out_dir/$imsindel_out_dir; imsindel --bam $tumor --chr chr$i --outd $out_dir/$imsindel_out_dir --indelsize 10000 --reffa $ref --thread 20'"
done
#chrX
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'cd $out_dir/$imsindel_out_dir; imsindel --bam $tumor --chr chrX --outd $out_dir/$imsindel_out_dir --indelsize 10000 --reffa $ref --thread 20'"

#pindel
pindel_out_dir="pindel_out"
eval "mkdir $out_dir/$pindel_out_dir"
eval "echo -e '$tumor 300 tumor\n$normal 300 normal' > $out_dir/$pindel_out_dir/pindel-config.txt"

pindel_config_file="$out_dir/$pindel_out_dir/pindel-config.txt"
pindel_out_name="pindel_out"
ref_name="(the name of reference)"
date="(date)"
#run
eval "docker run --rm -itv $mount_dir $sv_conductor /bin/bash -c 'cd $out_dir/$pindel_out_dir; pindel -f $ref -i $pindel_config_file -c ALL -o $pindel_out_name'"
#merge vcf
eval "docker run --rm $mount_dir $sv_conductor /bin/bash -c 'cd $out_dir/$pindel_out_dir; cat ${pindel_out_name}_D ${pindel_out_name}_SI ${pindel_out_name}_LI ${pindel_out_name}_TD ${pindel_out_name}_INV  > ${pindel_out_name}.txt; pindel2vcf -R $ref_name -r $ref -p ${pindel_out_name}.txt -v ${pindel_out_name}.vcf -d $date'"
