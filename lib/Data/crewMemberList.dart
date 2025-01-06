import 'package:hive/hive.dart';
import 'crewmember.dart';
part 'crewMemberList.g.dart';

@HiveType(typeId: 8)
class CrewMemberList extends HiveObject {
  @HiveField(0)
  List<CrewMember> crewMembers;

  CrewMemberList({required this.crewMembers});
}
