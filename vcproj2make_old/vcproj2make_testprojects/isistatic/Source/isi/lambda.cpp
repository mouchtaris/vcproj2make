#include "isi/lambda.h"

#include <assert.h>

namespace isi {

	Variable::Variable (Name_t const& _name): name(_name) {}
	Variable::Name_t const Variable::Name (void) const
		{ return name; }
	void Variable::operator >> (std::ostream& o) const
		{ o << name; }

	VariablesLifeSpace::VariableData::VariableData (void): varp(0x00) {}
	VariablesLifeSpace::VariablesLifeSpace (void) {}
	Variable& VariablesLifeSpace::GetVariable (Variable::Name_t const& varname) {
		VariableData& vd(vars[varname]);
		if (vd.varp == 0x00)
			vd.varp = new Variable(varname);
		return *vd.varp;
	}
	VariablesLifeSpace::~VariablesLifeSpace (void) {
		typedef VariablesMap_t::iterator ite_t;
		ite_t const end(vars.end());
		for (ite_t ite = vars.begin(); ite != end; ++ite) {
			assert( ite->second.varp );
			assert( ite->first == ite->second.varp->name );
			delete ite->second.varp;
		}
	}

	LambdaFunction::LambdaFunction (Variable const& _x, LambdaExpression const* const _e): x(_x), e(_e) {}
	void LambdaFunction::operator >> (std::ostream& o) const {
		o << "fun ";
		x >> o;
		o << "(";
		(*e) >> o;
		o << ")";
	}

	LambdaApplication::LambdaApplication (LambdaExpression const* const _e1, LambdaExpression const* const _e2): e1(_e1), e2(_e2) {}
	void LambdaApplication::operator >> (std::ostream& o) const {
		o << "(";
		(*e1) >> o;
		o << ")(";
		(*e2) >> o;
		o << ")";
	}

} // namespace isi