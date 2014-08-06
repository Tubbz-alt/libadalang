## vim: filetype=cpp

class ${cls.name()} : public ${base_name} {
protected:
public:

    % for t, f in zip(types, cls.fields):
         ${decl_type(t)} ${f.name};
    % endfor

    std::string repr();

    % if cls.fields:
        ${cls.name()}() : ${", ".join("{0}({1})".format(f.name, t.nullexpr()) for t, f in zip(types, cls.fields))} {}
    % endif

    std::string __name();
    ~${cls.name()}();
};

extern long ${cls.name().lower()}_counter;

% if not cls.is_ptr:
extern ${cls.name()} nil_${cls.name()};
% endif
