[DscResource()]
class PSConfEUDemo {
    [DscProperty(Key)] 
    [String] $Name

    [DscProperty(NotConfigurable)]
    [String] $ReverseName

    [PSConfEUDemo] Get () {
        return @{
            Name = $this.Name
            ReverseName = $this.Reverse($this.Name)
        }
    }
    [bool] Test () {
        return $false
    }
    [void] Set () {
        $Rev = $this.Reverse($this.Name)
        Write-Verbose -Message $Rev
    }

    [string] Reverse ([String] $Name) {
        #Wait-Debugger
        $ReverseIt = $Name.ToCharArray()
        [array]::Reverse($ReverseIt)
        return ($ReverseIt -join '')
    }
}