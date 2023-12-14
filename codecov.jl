import Pkg; Pkg.activate("."); Pkg.test(coverage=true)
using Coverage

function clear_coverage(folder=".")
    clean_folder(joinpath(folder, "src"))
    clean_folder(joinpath(folder, "test"))
end

# --- process '*.cov' files
coverage = process_folder()
# --- process '*.info' files, if you collected them
coverage = merge_coverage_counts(coverage, filter!(
    let prefixes = (joinpath(pwd(), "src", ""))
        c -> any(p -> startswith(c.filename, p), prefixes)
    end,
    LCOV.readfolder("test"))) 

# --- Get total coverage for all Julia files
covered_lines, total_lines = get_summary(coverage)
# --- Or process a single file
println("=== Covered Lines: $covered_lines")
println("=== Total Lines: $total_lines  ")
@info "Total coverage is $(round((covered_lines/total_lines)*100, digits=2)) %"
