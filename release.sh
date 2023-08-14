#
#  Copyright 2023 Alexey Andreev.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

set -e

TEAVM_RELEASE_VERSION=$1

function release_teavm {
  echo "Building version $TEAVM_RELEASE_VERSION"
  KEY_RING_FILE="$PWD/tmpring.gpg"
  echo "$TEAVM_GPG_KEY" > ./private.key
  gpg --no-default-keyring --keyring "$KEY_RING_FILE"  --import ./private.key
  TEAVM_GPG_KEY_ID=`gpg  --no-default-keyring --keyring "$KEY_RING_FILE" --keyid-format short --list-secret-keys  | awk '/^sec/ { print $2; exit }' | cut -d '/' -f 2`

  gpg --no-default-keyring --keyring "$KEY_RING_FILE" --export-secret-keys -o "$PWD/secring.gpg"
  KEY_RING_FILE="$PWD/secring.gpg"


  GRADLE="$PWD/gradlew"
  GRADLE+=" --no-daemon --no-configuration-cache --stacktrace"
  GRADLE+=" -Pteavm.mavenCentral.publish=true"
  GRADLE+=" -Pteavm.project.version=$TEAVM_RELEASE_VERSION"
  GRADLE+=" -Psigning.keyId=$TEAVM_GPG_KEY_ID"
  GRADLE+=" -Psigning.password=''"
  GRADLE+=" -Psigning.secretKeyRingFile=$KEY_RING_FILE"
  GRADLE+=" -PossrhUsername=$TEAVM_SONATYPE_LOGIN"
  GRADLE+=" -PossrhPassword=$TEAVM_SONATYPE_PASSWORD"

  $GRADLE build -x test || { echo 'Build failed' ; return 1; }
  $GRADLE --max-workers 1 publish publishPlugin publishPlugins || { echo 'Release failed' ; return 1; }

  rm "$PWD/tmpring.gpg" || true
  rm "$PWD/secring.gpg" || true
  rm "$PWD/private.key" || true
  return 0
}

release_teavm
