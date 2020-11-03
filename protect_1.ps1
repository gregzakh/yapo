using namespace System.Text
using namespace System.Management.Automation
using namespace System.Collections.ObjectModel

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
    [String]$OutFile = "$pwd\$(-join('a'..'z'+'A'..'Z'|Get-Random -Count 13)).ps1"
  )

  end {
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
      $String = Get-Content -Path $Path -Raw
    }

    while (($c = [PSParser]::Tokenize(
      $String, [ref]$null # do not obfuscate any comments
    ).Where{$_.Type -eq 'Comment'})) {
      $c = $c -is [Collection`1[PSObject]] ? $c[0] : $c
      $String = $String.Remove($c.Start, $c.Length + 2)
    }

    $bit, $out, $c, $sym = @{
      0 = "`$()-!{}", "!{}+!{}", "!{}-!{}"
      1 = "!!{}+!{}", "!!{}-!{}"
    }, '', 64, ('${<}', '${>}')

    $bit.Keys.ForEach{
      $out += "`${$([Char]($c-=2))}=$($bit.$_ | Get-Random);"
    }

    $c = $out + '$$=("' + (-join [Encoding]::ASCII.GetBytes($String).ForEach{
      ([Convert]::ToString($_, 2).PadLeft(8, '0') -split '').Where{$_}.ForEach{
        "$($sym[$_])"
      }
    }) + "`"-split'(\d{8})').Where{`$_}.ForEach{[Char][Convert]::ToInt32(`$_,2)};"
    $c += '.([ScriptBlock]::Create(-join$$))'
    Out-File -FilePath $OutFile -InputObject $c
  }
}
