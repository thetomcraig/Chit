version="${1}"
archive_name="chit.${version}"

tar -zcvf "${archive_name}" chit.sh build iterm theme_definitions
mv "${archive_name}" archive

echo $(shasum -a 256 archive/"${archive_name}" | awk '{print $1}')
