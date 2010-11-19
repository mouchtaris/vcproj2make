#ifndef __ISI__LAMBDA__H__
#define __ISI__LAMBDA__H__

#include <string>
#include <map>
#include <ostream>

namespace isi {

	
	class LambdaExpression {
	public:
		virtual void operator >> (std::ostream&) const throw() = 0;
	};

	class Variable: public LambdaExpression {
	public:
		typedef std::string Name_t;
	private:
		const Name_t name;
		Variable (Name_t const& _name = "") throw();
		friend class VariablesLifeSpace;
	public:
		const Name_t Name (void) const throw();

		void operator >> (std::ostream&) const throw();
	}; // class Variable

	class VariablesLifeSpace {
		struct VariableData {
			Variable* varp;
			VariableData (void) throw();
		};
		typedef std::map<Variable::Name_t, VariableData> VariablesMap_t;
		VariablesMap_t vars;
	public:
		VariablesLifeSpace (void) throw();
		~VariablesLifeSpace (void) throw();

		Variable& GetVariable (Variable::Name_t const& varName) throw();
	}; // class VariablesLifeSpace

	class LambdaFunction: public LambdaExpression { // lx.e
		Variable const x;
		LambdaExpression const* e;
	public:
		LambdaFunction (Variable const& _x, LambdaExpression const* const _e) throw();

		void operator >> (std::ostream&) const throw();
	}; // class LambdaFunction

	class LambdaApplication: public LambdaExpression {
		LambdaExpression const* const e1;
		LambdaExpression const* const e2;
	public:
		LambdaApplication (LambdaExpression const* const _e1, LambdaExpression const* const _e2) throw();

		void operator >> (std::ostream&) const throw();
	}; // class LambdaApplication

} // namespace isi

#endif // __ISI__LAMBDA__H__
