#!/usr/bin/bash

target_path=".."

create_docset() {
    docset="$1"
    docset_path="$target_path/$docset.docset"

    rm -rf "$docset_path"
    mkdir -p "$docset_path/Contents/Resources"

    cp -r "sdlwiki/$docset" "$docset_path/Contents/Resources/Documents"

    cp "icon.png" "$docset_path"
    cp "icon@2x.png" "$docset_path"

    cat > "$docset_path/meta.json" <<EOF
{
    "name": "$docset",
    "title": "$docset",
    "version": "1.0.0"
}
EOF

    cat > "$docset_path/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleIdentifier</key>
	<string>$docset</string>
	<key>CFBundleName</key>
	<string>$docset</string>
	<key>DocSetPlatformFamily</key>
	<string>$docset</string>
	<key>isDashDocset</key>
	<true/>
    <key>dashIndexFilePath</key>
    <string>FrontPage.html</string>
</dict>
</plist>

EOF

    docset_db="$docset_path/Contents/Resources/docSet.dsidx"
    {
        echo "CREATE TABLE searchIndex(id INTEGER PRIMARY KEY, name TEXT, type TEXT, path TEXT);"

        pushd "$docset_path/Contents/Resources/Documents" > /dev/null

        echo "BEGIN TRANSACTION;"

        find -maxdepth 1 -type f -print | while read path; do
            # remove prefix ./
            path=${path#./}
            
            # remove .html suffix
            name=${path%.html}

            type='File'

            if [[ $name == Category* ]]; then
                type='Category'
                name=${name#Category}
            elif [[ $name =~ ^[A-Z_]+$ ]]; then
                type='Define'
            elif [[ $name == SDL_* ]]; then
                type='Function'
            fi
            echo "INSERT INTO searchIndex(name, type, path) VALUES ('$name', '$type', '$path');"
        done

        echo "COMMIT;"

        popd > /dev/null
    } | sqlite3 "$docset_db"
}


ls sdlwiki | while read group; do
    create_docset "$group"
done

