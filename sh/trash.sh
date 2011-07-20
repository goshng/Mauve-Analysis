
function compute-watterson-estimate-for-clonalframe {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      set-more-global-variable 
      # Find all the blocks in FASTA format.
      echo -e "  Computing Wattersons's estimates...\n"
      rm -f $DATADIR/core_alignment.xmfa.*
      perl pl/blocksplit2fasta.pl $DATADIR/core_alignment.xmfa
      #run-blocksplit2smallerfasta 
      # Compute Watterson's estimate.
      compute-watterson-estimate > w.txt
      # Use R to sum the values in w.txt.
      sum-w
      rm w.txt
      echo -e "You may use the Watterson's estimate in clonalframe analysis.\n"
      echo -e "Or, you may ignore.\n"
      break
    fi
  done
}

function recombination-intensity3 {
  cat>$RUNANALYSIS/recombination-intensity3.R<<EOF
x <- read.table ("$RUNANALYSIS/recombination-intensity.txt.sgr")
length(x\$V3[x\$V3<1])/length(x\$V3)
stem(x\$V3)
postscript("$RUNANALYSIS/recombination-intensity.eps", width=10, height=10)
hist(x\$V3, main="Distribution of number of recombinant edge types", xlab="Number of recombinant edge types")
dev.off()
EOF
  R --no-save < $RUNANALYSIS/recombination-intensity3.R
}

function analysis-clonalorigin {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "Which replicate set of output files?"
      echo -n "REPLICATE ID: " 
      read REPLICATE
      set-more-global-variable 
 
      select WHATANALYSIS in recombination-intensity \
                             recombination-intensity2 \
                             recombination-intensity3 \
                             gene-flow \
                             convergence \
                             heatmap \
                             import-ratio-locus-tag \
                             summary \
                             recedge \
                             recmap \
                             traceplot \
                             parse-jcvi-role \
                             combine-import-ratio-jcvi-role; do 
        if [ "$WHATANALYSIS" == "" ];  then
          echo -e "You need to enter something\n"
          continue
        elif [ "$WHATANALYSIS" == "convergence" ];  then
          echo -e "Checking convergence of parameters for the blocks ...\n"
          #rm -f $RUNCLONALORIGIN/output/convergence.txt
          #for i in {1..100}; do
          #for i in {101..200}; do
          #for i in {201..300}; do
          for i in {301..415}; do
            ALLTHREEDONE=YES
            for j in {1..3}; do
              FINISHED=$(tail -n 1 $RUNCLONALORIGIN/output/$j/core_co.phase2.$i.xml)
              if [[ "$FINISHED" =~ "outputFile" ]]; then
                ALLTHREEDONE=YES
              else
                ALLTHREEDONE=NO
                break
              fi
            done

            if [ ! -f "$RUNCLONALORIGIN/output/convergence-$i.txt" ]; then
              if [[ "$ALLTHREEDONE" = "YES" ]]; then
                echo "Block: $i" > $RUNCLONALORIGIN/output/convergence-$i.txt
                echo -e "Computing Gelman-Rubin Test ...\n"
                $GUI -b -o $RUNCLONALORIGIN/output/1/core_co.phase2.$i.xml \
                  -g $RUNCLONALORIGIN/output/2/core_co.phase2.$i.xml,$RUNCLONALORIGIN/output/3/core_co.phase2.$i.xml:1 \
                  >> $RUNCLONALORIGIN/output/convergence-$i.txt
                echo -e "Finding blocks with insufficient convergence ...\n"
                perl $PERLGUIPERL -in $RUNCLONALORIGIN/output/convergence-$i.txt
              else
                echo "Block: $i do not have all replicates" 1>&2
              fi
            fi
          done 

          #echo -e "Finding blocks with insufficient convergence ...\n"
          #perl $PERLGUIPERL -in $RUNCLONALORIGIN/output/convergence.txt
          #break

          break
        elif [ "$WHATANALYSIS" == "traceplot" ];  then
          echo -e "Trace plots ... \n"
          perl $ECOP3 \
            $RUNCLONALORIGIN/output/${REPLICATE}/core*.xml \
            > $RUNCLONALORIGIN/log3.p
          echo -e "Splitting the log files ...\n"
          split -l 100 $RUNCLONALORIGIN/log3.p
          for s in x*; do
            echo -e "${s}.Gen\t${s}.f\t${s}.iter\t${s}.ll\t${s}.prior\t${s}.theta\t${s}.rho\t${s}.delta\n" |cat - $s > /tmp/out && mv /tmp/out $s
          done
          echo -e "Combine all trace files ...\n"
          rm -f /tmp/in
          touch /tmp/in
          for s in x*; do
            paste /tmp/in $s > /tmp/out 
            mv /tmp/out /tmp/in
          done
          mv /tmp/in a.log
          rm x* 
          break
        elif [ "$WHATANALYSIS" == "parse-jcvi-role" ];  then
          echo -e "Parsing jcvi_role.html to find role identifiers ...\n"
          #perl pl/parse-jcvi-role.pl -in $RUNANALYSIS/jcvi_role.html > $RUNANALYSIS/jcvi_role.html.txt
          echo -e "Parsing jcvi_role.html to find role identifiers ...\n"
          #perl pl/parse-m3-locus.pl \
          #  -primary $RUNANALYSIS/bcp_m3_primary_locus.txt \
          #  -jcvi $RUNANALYSIS/bcp_m3_jcvi_locus.txt > \
          #  $RUNANALYSIS/bcp_m3_primary_to_jcvi.txt
          echo -e "Getting one-to-one relationships of locus_tag and JCVI loci ..."
          #perl pl/get-primary-jcvi-loci.pl $RUNANALYSIS/get-primary-jcvi-loci.txt
          echo -e "Listing locus_tags, their gene ontology, and JCVI roles" 
          #perl pl/list-locus-tag-go-jcvi-role.pl \
          #  -bcpRoleLink=$RUNANALYSIS/bcp_role_link \
          #  -bcpGoRoleLink=$RUNANALYSIS/bcp_go_role_link \
          #  -locusTagToJcviLocus=$RUNANALYSIS/get-primary-jcvi-loci.txt \
          #  > $RUNANALYSIS/list-locus-tag-go-jcvi-role.txt
          break
        elif [ "$WHATANALYSIS" == "combine-import-ratio-jcvi-role" ];  then
          echo -e "Combining import-ratio and jcvi-role ..."
          echo perl pl/combine-import-ratio-jcvi-role.pl \
            -importRatio $MAUVEANALYSISDIR/import-ratio-with-sde1.txt \
            -jcviRole $RUNANALYSIS/list-locus-tag-go-jcvi-role.txt
          break
        elif [ "$WHATANALYSIS" == "plot-import-ratio-jcvi-role" ];  then
          echo -e "Plotting import-ratio and jcvi-role ..."
          echo perl pl/plot-import-ratio-jcvi-role.pl \
            -importRatio $MAUVEANALYSISDIR/combine-import-ratio-jcvi-role.txt \
            -jcviRole $RUNANALYSIS/list-locus-tag-go-jcvi-role.txt
        fi
      done
      break
    fi
  done
}

