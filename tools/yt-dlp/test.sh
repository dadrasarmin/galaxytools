#!/usr/bin/env bash
# Test harness for Galaxy yt-dlp wrapper
# Set variables (customize these as needed):

# Input playlist/video URLs file
input_file="test-data/input-test10.txt"

# Galaxy variables
GALAXY_SLOTS_DIR="$(mktemp -d)"
supported="$GALAXY_SLOTS_DIR/supported_urls.txt"
unsupported="$GALAXY_SLOTS_DIR/unsupported_urls.txt"

# Advanced options (empty to disable)
write_comments="--write-comments"
max_downloads="--max-downloads 20"
dateafter="--dateafter 19700101"
datebefore="--datebefore 20500101"
embed_subs=""
write_subs="--write-subs"
sub_langs="--sub-lang all"
write_info="--write-info-json"

# Extraction or download mode
# To extract audio: extract_mode="-x" and set audio_quality
# To download video: leave extract_mode blank and set video_quality
extract_mode=""
video_quality="best*"    # e.g. best*, worst*
audio_quality="--audio-quality 5"

# Output paths
video_out="%(title)s%(id)s%(ext)s"
audio_out="%(title)s%(id)s%(ext)s"
info_out="%(title)s%(id)s%(ext)s"
subs="%(title)s%(id)s%(ext)s"

# Whitelist splitting (as in wrapper)
grep -E '^(https?://(www\.)?(youtube\.com|mastodon\.social|vimeo\.com|instagram\.com|tiktok\.com)/)' "$input_file" > "$supported"
grep -v -E '^(https?://(www\.)?(youtube\.com|mastodon\.social|vimeo\.com|instagram\.com|tiktok\.com)/)' "$input_file" > "$unsupported"

# Check unsupported
if [ -s "$unsupported" ]; then
    cat "$unsupported" >> unsupported_sites.txt
fi

# Build yt-dlp command
CMD=( yt-dlp --quiet --socket-timeout 120 --limit-rate 1M --retries 10 --no-embed-thumbnail
    $write_comments $max_downloads $dateafter $datebefore
    $embed_subs $write_subs $sub_langs $write_info $extract_mode )

if [ "$extract_mode" = "-x" ]; then
    CMD+=( --audio-format mp3 $audio_quality --output "$audio_out" )
else
    CMD+=( --format "$video_quality" --recode-video mp4 --output "$video_out" )
fi

CMD+=( --batch-file "$supported" )

# Show and execute
echo "> ${CMD[@]}"
"${CMD[@]}"

# Post-process outputs
if [ "$write_info" = "--write-info-json" ] && compgen -G "*.info.json" > /dev/null; then
    mv *.info.json "$info_out"
fi
if [ "$write_subs" = "--write-subs" ] && compgen -G "*.srt" > /dev/null; then
    mv *.srt "$subs"
fi

echo "Done. Outputs:"
ls -l $video_out $audio_out $info_out $subs