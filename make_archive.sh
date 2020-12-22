version="${1}"

archive_name="chit_macos_10.15.tar.gz"

tar -zcvf "${archive_name}" chit.sh build iterm
mv "${archive_name}" archive

echo $(shasum -a 256 archive/"${archive_name}" | awk '{print $1}')
