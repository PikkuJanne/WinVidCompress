function Assert-WvcWebsiteReleaseFields($Document) {
    $fields=@('published_version','release_date','release_url','download_url','sha256')
    foreach ($field in $fields) {
        if (-not $Document.PSObject.Properties[$field]) {throw ('Missing release field: '+$field)}
    }
    if ($Document.status -ceq 'draft_not_for_publication') {
        foreach ($field in $fields) {
            if ($null -ne $Document.$field) {throw ('Draft has a populated release field: '+$field)}
        }
        return
    }
    if ($Document.status -cne 'published') {throw 'Unsupported publication state.'}
    if ($Document.published_version -cnotmatch '^[0-9]+\.[0-9]+\.[0-9]+\z') {throw 'Invalid released version.'}
    $date=[datetime]::MinValue
    if (-not [datetime]::TryParseExact($Document.release_date,'yyyy-MM-dd',
        [Globalization.CultureInfo]::InvariantCulture,[Globalization.DateTimeStyles]::None,[ref]$date)) {
        throw 'Invalid release date.'
    }
    if ($Document.sha256 -cnotmatch '^[a-f0-9]{64}\z') {throw 'Invalid release ZIP checksum.'}
    $root='https://github.com/PikkuJanne/WinVidCompress/releases'
    $tag='v'+$Document.published_version
    if ($Document.release_url -cne ($root+'/tag/'+$tag)) {throw 'Release URL version mismatch.'}
    if ($Document.download_url -cne ($root+'/download/'+$tag+'/WinVidCompress-'+$Document.published_version+'.zip')) {
        throw 'Download URL/tag/filename version mismatch.'
    }
}
