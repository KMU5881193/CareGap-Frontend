from pathlib import Path
from concurrent.futures import ThreadPoolExecutor
import shutil,sys,tempfile
source=Path(sys.argv[1]).expanduser().resolve()
if not (source/'pubspec.yaml').is_file() or not (source/'ios/Runner.xcodeproj').is_dir(): raise SystemExit('iOS 폴더가 있는 Flutter 프로젝트 경로가 필요합니다.')
target=Path(tempfile.mkdtemp(prefix='caregap-ios-',dir='/private/tmp'))
skip={'build','.dart_tool','.git','Pods','ephemeral','SourcePackages','.symlinks','Generated.xcconfig','flutter_export_environment.sh','.flutter-plugins-dependencies'}
files=[]
def walk(folder):
 for f in folder.iterdir():
  if f.name in skip or f.is_symlink(): continue
  if f.is_dir(): walk(f)
  elif f.is_file(): files.append(f)
for name in ['ios','lib','assets','pubspec.yaml','pubspec.lock','analysis_options.yaml']:
 f=source/name
 if f.is_dir(): walk(f)
 elif f.is_file(): files.append(f)
def copy(f):
 dest=target/f.relative_to(source);dest.parent.mkdir(parents=True,exist_ok=True)
 shutil.copyfile(f,dest)
with ThreadPoolExecutor(max_workers=12) as pool: list(pool.map(copy,files))
print(target)
