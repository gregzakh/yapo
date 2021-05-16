function Protect-PSCode {
  [CmdletBinding(DefaultParameterSetName='Path')]
  param(
    [Parameter(Mandatory, ParameterSetName='Path', Position=0)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript({Test-Path $_})]
    [String]$Path,

    [Parameter(Mandatory, ParameterSetName='String', Position=0)]
    [ValidateNotNullOrEmpty()]
    [String]$String,

    [Parameter()]
    [ValidateRange(1, 25)]
    [Byte]$Key = 1,

    [Parameter()]
    [String]$OutFile = "$pwd\$(-join('a'..'z'+'A'..'Z'|Get-Random -Count 13)).ps1"
  )

  end {
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
      $String = Get-Content -Path $Path -Raw
    }

    [Char[][]]$arr = ('a'..'z'+'A'..'Z'), $String.Trim()
    $x = -join$(for ($i = 0; $i -lt $arr[1].Length; $i++) {
      $arr[1][$i] -in $arr[0] ? $(
        [Char]::"To$([Char]::IsUpper($arr[1][$i]) ? 'Upp' : 'Low')er"(
          $arr[0][($arr[0].IndexOf($arr[1][$i]) + $Key) % $arr[0].Length]
        )
      ) : [Uri]::EscapeDataString($arr[1][$i])
    })
    $out = "`'$x`'|sv x;`$x,`$k,`$a=[Char[]][Uri]::UnescapeDataString(`$x)"
    $out += ",($Key*-1),('a'..'z'+'A'..'Z');-join`$(`$x.ForEach{`$_-in`$a"
    $out += " ? `$([Char]::`"To`$([Char]::IsUpper(`$_) ? 'Upp' : 'Low')er`""
    $out += "(`$a[(`$a.IndexOf(`$_)+`$k)%`$a.Length])) : `$_})|sv x;"
    $out += "[ScriptBlock]::Create(`$x).Invoke()"
    Out-File -FilePath $OutFile -InputObject $out
  }
}
