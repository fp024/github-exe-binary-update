# Github에서 exe 파일로 제공하는 프로그램들의 공통 다운로드 스크립트

> [google-java-format](https://github.com/google/google-java-format), [oh-my-posh](https://github.com/JanDeDobbeleer/oh-my-posh), [yt-dlp](https://github.com/yt-dlp/yt-dlp) 등이 exe 바이너리를 Github를 통해 배포되는데,
>
> 버전업이 있을 때마다, 이 프로그램들을 수동으로 다운로드 받기가 귀찮아서 공통 스크립트를 만들었다.
>
> 💡 원래는 여러가지 잡동사니 모아둔 리포지토리의 하위에 만들어놨던 프로젝트인데, 기능을 조금씩 추가하게 되어서, 별도 리포지토리로 분리했다.

## 설치 방법

### 자동 설치 (권장)

`install.bat`을 사용하여 자동으로 심볼릭 링크를 생성할 수 있습니다.

**1. 설치 가능한 프로그램 확인**

```cmd
install.bat
```

**2. 프로그램 설치**

```cmd
install.bat [프로그램명] [설치경로]
```

**예시:**

```cmd
install.bat google-java-format C:\google-java-format
install.bat oh-my-posh C:\oh-my-posh
install.bat yt-dlp C:\yt-dlp
```

**요구사항:**
- Windows에서 심볼릭 링크를 생성하려면 다음 중 하나가 필요합니다:
  - **관리자 권한으로 실행**: Ctrl + Shift를 누른 채로 CMD 또는 Windows 터미널 실행
  - **개발자 모드 활성화** (Windows 10/11): 설정 > 업데이트 및 보안 > 개발자용 > 개발자 모드

**설치되는 파일:**
- `settings\[프로그램명].properties` → `[설치경로]\settings.properties` (심볼릭 링크)
- `update.bat` → `[설치경로]\update.bat` (심볼릭 링크)
- `scripts\` → `[설치경로]\scripts\` (정션 링크)

## update.bat 기능 명세

### 동작 방식
1. **설정 파일 로드**: `settings.properties`에서 설정값들을 읽어옴
2. **로컬 버전 확인**: 
   - 실행 파일이 존재하면 `EXECUTABLE_NAME VERSION_OPTION` 명령으로 버전 확인
   - 실행 파일이 없으면 `LOCAL_VERSION=none`으로 설정
3. **최신 버전 확인**: GitHub API를 통해 최신 릴리즈 태그 가져오기
   * JSON응답 결과를 파싱하여, tag_name을 획득 (예:  "tag_name": "v1.28.0")
   * **예시)** Google Java Format 의 최신 버전 확인 API
     * https://api.github.com/repos/google/google-java-format/releases/latest
4. **버전 비교**: 로컬 버전과 최신 버전 비교
5. **다운로드 결정**: 
   - 버전이 다르거나 로컬 파일이 없는 경우 다운로드 진행
   - 사용자 확인 후 다운로드 실행
   - 파일은 우선 임시파일 이름으로 다운로드함
6. **바이러스 검사** :
   * WinRAR의 바이러스 검사 기능이 생각나서 추가해봄.
     * 다음 프로그램과 인자 사용
       * 윈도우디펜더 커맨더 라인 실행 프로그램: `C:\Program Files\Windows Defender\MpCmdRun.exe`
       * 전달인자: `-Scan -ScanType 3 -File "%f"`
7. **파일 검증**:
   * GitHub API 결과중 파일 크기(size)와 파일 해시(digest)가 일치 하는지 확인
   * 일치하지 않을경우 임시 다운로드 파일을 교체하지 않고 실패로 처리
   * 파일 검증이 성공하면 임시 파일을 실제 사용 파일로 교체함

### 핵심 로직
- **파일 없음 처리**: `LOCAL_VERSION=none`으로 설정되어, 최신 버전과 달라지므로 자연스럽게 신규 다운로드 시작
- **사용자 확인**: 신규 다운로드 & 새로운 버전 업데이트 전 항상 사용자 승인 요청



### settings.properties 설정 항목

- `LATEST_VERSION_URL`: GitHub API 릴리즈 URL
- `DOWNLOAD_URL`: 최신 릴리즈 다운로드 URL
- `EXECUTABLE_NAME`: 실행 파일명
- `VERSION_OPTION`: 로컬 바이너리의 버전 확인 명령어 옵션

  ```properties
  # google-java-format
  VERSION_OPTION=--version
  # oh-my-posh
  VERSION_OPTION=version
  # ...
  ```

- `VERSION_PREFIX`: 로컬 바이너리의 버전 확인 출력 결과에서 버전이 출력되는 접두어 패턴 정의

  대부분의 프로그램은 버전 번호만 출력되지만, 드물게 접두어가 붙어서 출력되는 경우에 대한 대응 설정

  ```properties
  # oh-my-posh, yt-dlp의 경우는 버전만 출력하므로 아래와 같이 접두어 설정을 빈값으로 둠
  VERSION_PREFIX=
  # google-java-format의 경우는 google-java-format: Version 이라는 접두어가 붙음
  VERSION_PREFIX=google-java-format: Version 
  ```



## 사용 예시 (google-java-format)

설치 후 대상 디렉토리에서 `update.bat`을 실행하면 최신 버전을 확인하고 다운로드합니다.

```
C:\google-java-format>update.bat
--- Options ---
LATEST_VERSION_URL=https://api.github.com/repos/google/google-java-format/releases/latest
DOWNLOAD_URL=https://github.com/google/google-java-format/releases/latest/download/google-java-format_windows-x86-64.exe
EXECUTABLE_NAME=google-java-format_windows-x86-64.exe
VERSION_OPTION=--version
VERSION_PREFIX=google-java-format: Version
---------------
google-java-format_windows-x86-64.exe not found locally.
Local  version: none
Latest version: google-java-format: Version 1.28.0
Expected file size: 31342592 bytes
Expected SHA256: 3242e4a2e86c757397d207bb64c86dbc401b3eace7387084cef88843c62dc08e
✨✨✨ Please Check Version ✨✨✨
Would you like to update? (y/n): y
Downloading the latest version of google-java-format_windows-x86-64.exe.
Download successful. Verifying file integrity...
Actual file size: 31342592 bytes
✅ File size verification passed.
Running Windows Defender scan on: C:\google-java-format\google-java-format_windows-x86-64.exe_temp.exe
✅ Security scan completed - no threats detected.
✅ Security check passed.
Calculating SHA256 hash... (this may take a moment)
Actual SHA256: 3242e4a2e86c757397d207bb64c86dbc401b3eace7387084cef88843c62dc08e
✅ SHA256 verification passed. File integrity confirmed
Replacing the original file...
🎉 File successfully updated and verified 🎉
👍 Task completed.
Press Enter key to continue...


C:\google-java-format>
```



## [tests/test_security_scan.bat](tests/test_security_scan.bat) - 바이러스 검사 테스트 배치 파일

실제 상황에서 바이러스 검사가 제대로 되는지 확인하기 어려워서, EICAR 문자열을 활용한 바이러스 검사 테스트 배치 파일을 추가했다.

```
==================== MpCmdRun.exe Output ====================
Scan starting...
Scan finished.
Scanning C:\git\github-exe-binary-update\tests\eicar_test.exe found 1 threats.
==================== End of MpCmdRun.exe Output ====================
```

테스트는 잘 동작하였다, MpCmdRun.exe가 ExitCode로 바이러스를 검출했는지 않했는지로 구분할 수 가 없어서...

MpCmdRun.exe가 출력하는 다음 출력 내용으로 구분해야했는데...

* 검출 되지 않을 경우

  ```
  found no threats
  ```

* 검출 되었을 경우

  ```
  found 1 threats
  ```

  * 숫자부분은 검출 갯수

MpCmdRun.exe의 출력 결과가 윈도우 11 한글판 및 영문판에서 모두 동일하게 영문으로 출력됨을 확인했다.
