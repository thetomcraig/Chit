version="${1}"
archive_name="chit.${version}.tar.gz"

tar -zcvf "${archive_name}" chit.sh build iterm example_theme_definitions
mv "${archive_name}" archive

echo $(shasum -a 256 archive/"${archive_name}" | awk '{print $1}')

git add archive
git commit -m "Add version ${version} archive"
git push
