## vim: filetype=cpp

#include <boost/program_options/cmdline.hpp>
#include <boost/program_options/options_description.hpp>
#include <boost/program_options/variables_map.hpp>
#include <boost/program_options/parsers.hpp>
#include <cstdlib>
#include "${header_name}"
#include <fstream>

namespace po = boost::program_options;
using namespace std;

void parse_input(Lexer* lex, string rule_name, bool print) {
    % for i, (rule_name, combinator) in enumerate(_self.rules_to_fn_names.items()):
        ${"if" if i == 0 else "else if"} (rule_name == ${c_repr(rule_name)}) {
            auto res = ${combinator.gen_fn_name}(lex, 0);

            if (current_pos == -1) {
                printf("Failed !!\n");
                printf("Last token pos : Line %d, Col %d, cat %d\n", 
                       max_token.line_n, max_token.column_n, max_token._id);
            } else {
                % if combinator.needs_refcount():
                    res${"->" if combinator.get_type().is_ptr else "."}inc_ref();
                % endif
                current_pos = 0;
                if (print)
                    printf("%s\n", get_repr(res).c_str());
                % if combinator.needs_refcount():
                    res${"->" if combinator.get_type().is_ptr else "."}dec_ref();
                % endif
            }

            clean_all_memos();
        }
    % endfor
    else {
        printf("Unknown rule : %s\n", rule_name.c_str());
    }
}

int main (int argc, char** argv) {

    po::options_description desc("Allowed options");
    desc.add_options()
        ("help", "produce help message")
        ("silent,s", po::value<bool>()->default_value(false)
                                       ->implicit_value(true)
                                       ->zero_tokens(), 
         "print the representation of the resulting tree")
        ("files,f", po::value<vector<string>>(), 
         "trigger the file input mode")
        ("filelist,F", po::value<string>(), "list of files")
        ("rule-name,r", po::value<string>()->default_value("compilation_unit"), "rule name to parse")
        ("input", po::value<string>()->default_value(""), "input file or string");

    po::variables_map vm;
    po::positional_options_description p;
    p.add("input", -1);
    po::store(po::command_line_parser(argc, argv).
              options(desc).positional(p).run(), vm);
    po::notify(vm);


    if (vm.count("help") or !(vm.count("input"))) {
        cout << "Not enough arguments !\n";
        cout << desc << "\n";
        return 1;
    }

    Lexer* lex;
    string input = vm["input"].as<string>();
    string rule_name = vm["rule-name"].as<string>();
    bool print = !vm["silent"].as<bool>();

    if (vm.count("filelist")) {
        std::ifstream fl(vm["filelist"].as<string>());
        string input_file;
        while (std::getline(fl, input_file)) {
            input_file = trim(input_file);
            if (input_file != "") {
                cout << "file name : " << input_file << endl; lex = make_lexer_from_file(input_file.c_str(), nullptr);
                parse_input(lex, rule_name, print);
                free_lexer(lex);
            }
        }
    } else if (vm.count("files")) {
        auto input_files = vm["files"].as<vector<string>>();
        for (auto input_file : input_files) {
            cout << "file name : " << input_file << endl;
            lex = make_lexer_from_file(input_file.c_str(), nullptr);
            parse_input(lex, rule_name, print);
            free_lexer(lex);
        }
    } else {
        lex = make_lexer_from_string(input.c_str(), input.length());
        parse_input(lex, rule_name, print);
        free_lexer(lex);
    }

    
    print_diagnostics();
    return 0;
}
