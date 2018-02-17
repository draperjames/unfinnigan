
:: Building python package
:: using twine (https://github.com/pypa/twine).

:: This probably will need to be changed.

:: Update the git repo.
git add -A
git commit -m "package builder"
:: Cleaning up from last build.
git clean -fdx

:: Building the package like normal.
python setup.py sdist bdist_wheel

:: Uploading with twine.
twine upload dist/*

timeout 10
