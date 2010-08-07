main = std::vmload("DeltaIDE_2_Make/Lib/main.dbc", "main");
std::vmrun(main);

args = [ "deltaide2make", "IDE",
//	"../../../../thesis_new/deltaide/IDE/IDE.sln"
	"../vcproj2make_old/vcproj2make_testprojects/vcproj2make_testprojects.sln"
];
main.main(
	std::tablength(args),
	args,
	[]
);
