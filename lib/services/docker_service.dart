import '../models/docker_info.dart';
import '../platform/linux/linux_docker_provider.dart';

class DockerService {
  DockerService(this._provider);

  final LinuxDockerProvider _provider;

  Future<DockerInfo> loadDockerInfo() => _provider.readDockerSnapshot();
}
