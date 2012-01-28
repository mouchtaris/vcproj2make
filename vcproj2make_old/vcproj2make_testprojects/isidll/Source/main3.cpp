#include "main3.h"

#include <iostream>


class Vector {
public:
	Vector Add(Vector v);
	Vector DotProduct(Vector v);
	Vector CrossProduct(Vector v);
	bool   IsEqual(Vector v);

	float GetX(void)
		{return x;}
	void SetX(float x)
		{ Vector::x = x; }

	void operator ++ (void) const {
	}

private:
	float x, y, z;
};

Vector v;
Vector& operator *(Vector& p) {
	std::cout << "dereferecing " << &p << std::endl;
	return ::v;
}

Vector& operator +(Vector& p) {
	std::cout << "adding " << & p << std::endl;
	return ::v;
}

Vector& operator +(Vector& p, Vector& p2) {
	std::cout << "adding " << &p << ", " << &p2 << std::endl;
	return ::v;
}


int main3 (int argc, char *argv[]) throw () {
	(void) argc; (void) argv;

	Vector v;
	+v + *v;
	Vector* vp = 0x00;
	Vector& vr(*static_cast<Vector*>(0x00));
	std::cout << vp << " " << &vr << std::endl;
	v.SetX(12);
	std::cout << v.GetX() << std::endl;
	return 0;
}

