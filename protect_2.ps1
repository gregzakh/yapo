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

    [Parameter(Position=1)]
    [String]$OutFile = "$pwd\$(-join('a'..'z'+'A'..'Z'|Get-Random -Count 13)).ps1"
  )

  end {
    if ($PSCmdlet.ParameterSetName -eq 'Path') {
      $String = Get-Content -Path $Path -Raw
    }

    $r = 79..158 # additional bytes
    $x = "`'$(-join ([Text.Encoding]::ASCII.GetBytes($String)).ForEach{
      [BitConverter]::ToChar([Byte[]]($_, (Get-Random $r)))
    })`'-split''|?{`$_}|%{[BitConverter]::GetBytes([Char]`$_)[0]}|sv x"
    $x += ';.([ScriptBlock]::Create([Text.Encoding]::ASCII.GetString($x)))'
    Out-File -FilePath $OutFile -InputObject $x
  }
}
