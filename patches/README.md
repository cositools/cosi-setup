# Creating and applying patches

## Create a patch:

(1)
For example:
diff -rupN root_v5.34.32_unpatched/root_v5.34.32-source root_v5.34.32_patched/root_v5.34.32-source > root_v5.34.32.patch

(2)
Append it to an existing one if there is any

(3)
Add it to the cosi-setup/patches directory


## Apply the patch:

No need to dpo anything, the COSI setup scripts will do that for you. However, just for reference:


(1) Switch to the ROOT directory which you want to patch, e.g.
cd $COSITOOLS/external/root_v5.34.32

(2) Apply the patch
patch -p1 < $COSITOOLS/cosi-setup/patches/root_v5.34.32.patch 

(3) Recompile root
cd $COSITOOLS/external/root_v5.34.32/root_v5.34.32-build
make install

(4)
Done! ... there is no need to recompile any COSI tools


