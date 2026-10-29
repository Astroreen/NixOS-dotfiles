_: {
  custom.services.nextcloud-aio = {
    enable = true;
    apacheIpBinding = "0.0.0.0";
    # The big storage disk, shown in Nextcloud through the External storage app.
    nextcloudMount = "/mnt/nextcloud_storage";
    communityContainers = [ "facerecognition" ];
    enableNvidiaGpu = true;
    enableDriDevice = true;
    environment.NEXTCLOUD_MAX_TIME = "3600";
  };
}
