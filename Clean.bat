for /r ".\" %%a in (.) do (
  pushd %%a
  del *.tvsconfig
  del *.res
  del *.local
  del *.identcache
  rmdir /s /q __history
  popd
)
