cd $WORKSPACE
rm -rf build_parent
mv build-root build_parent
cp -r build_new build-root
# Create symlinks so that if job fails on robot test, results can be archived.
ln -s csit csit_new
