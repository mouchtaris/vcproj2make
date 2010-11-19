#include "main4.h"
//
#include "isi/lambda.h"
//
#include <iostream>

int main4 (int argc, char* argv[]) throw() {
	(void) argc; (void) argv;

	isi::VariablesLifeSpace vls;
	isi::Variable& x(vls.GetVariable("x"));
	isi::LambdaFunction l_id(x, &x);
	l_id >> std::cout;
	std::cout << std::endl;

	isi::Variable& s(vls.GetVariable("s"));
	isi::Variable& z(vls.GetVariable("z"));
	isi::LambdaApplication app_1z(&s, &z);
	isi::LambdaFunction l_1z(z, &app_1z);
	isi::LambdaFunction l_1(s, &l_1z);
	l_1 >> std::cout;
	std::cout << std::endl;

	return 0;
}
