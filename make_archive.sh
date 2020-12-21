version="${1}"

archive_name="chit.${version}.tar.gz"

tar -zcvf "${archive_name}" chit.sh build iterm
mv "${archive_name}" archive
