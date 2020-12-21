version="${1}"

archive_name="chit.${version}.tar.gz"

cd ..
tar -zcvf "${archive_name}" chit
mv "${archive_name}" chit/archive
