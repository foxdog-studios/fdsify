#!/bin/bash

# Copyright 2013 Foxdog Studios Ltd
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o nounset

readonly REPO="$(
    readlink -f -n -- "$(
        dirname -- "$(
            readlink -f -- "${BASH_SOURCE[0]}"
        )"
    )/../"
)"

cd -- "${REPO}"

mkdir -p config/
rm -f config/credentials

for deck in 'left' 'right'; do
    echo "${deck} deck"
    read -p 'Unix user: ' user
    read -p 'Spotify user: ' login
    read -p 'Spotify password: ' password
    echo "${user}" "${login}" "${password}" >> config/credentials
done

