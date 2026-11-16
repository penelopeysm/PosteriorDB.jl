load_json(path) = format_json_data(JSON.parsefile(path))

function load_zipped_file(f, path)
    reader = ZipFile.Reader(path)
    filename = splitext(basename(path))[1]
    files = filter(file -> file.name == filename, reader.files)
    nfiles = length(files)
    if nfiles != 1
        throw(
            ArgumentError(
                "Expected zip archive $path to contain exactly one file named $filename. Found $nfiles",
            ),
        )
    end
    result = f(first(files))
    close(reader)
    return result
end

load_zipped_json(path) = load_zipped_file(format_json_data ∘ JSON.parse, path)

load_zipped_string(path) = load_zipped_file(Base.Fix2(read, String), path)

function filenames_no_extension(path, ext; kwargs...)
    filenames = filter!(Base.Fix2(endswith, ext), readdir(path; kwargs...))
    return map(fn -> fn[1:(end - length(ext))], filenames)
end

format_json_data(data) = data
function format_json_data(data::AbstractDict)
    return OrderedDict{String,Any}(k => format_json_data(v) for (k, v) in data)
end
# Nested arrays are stacked into a single array, with the outermost array as the first dimension.
function format_json_data(data::AbstractVector)
    isempty(data) && return data
    elements = map(format_json_data, data)
    T = mapreduce(typeof, promote_type, elements)
    arr = convert(Vector{T}, elements)
    return T <: AbstractArray ? stack(arr; dims=1) : arr
end
