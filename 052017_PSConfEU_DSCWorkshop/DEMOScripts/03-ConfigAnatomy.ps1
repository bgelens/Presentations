Configuration ArchiveDemo {
    Node localhost {
        Archive ArchiveDemo {
            Path = "C:\demoscripts\Scripts.zip"
            Destination = "C:\Scripts"
            Ensure="Present"
        }
    }
}