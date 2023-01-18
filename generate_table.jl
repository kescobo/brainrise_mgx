using DataFrames
using CSV

#-
knead = DataFrame(path = readdir("output/kneaddata/", join=true))
knead.file = basename.(knead.path)
transform!(knead, "file"=> ByRow(f-> join(split(f, "_")[1:3], "_")) => "sequence_id")
transform!(knead, "file"=> ByRow(f-> join(split(f, "_")[1:2], "_"))=> "sample_id")
transform!(knead, "sequence_id"=> ByRow(f-> last(split(f, "_")))=> "well_id")
transform!(knead, "file"=> ByRow(f-> replace(replace(last(split(f, "_kneaddata")), ".fastq.gz"=> ""), r"_|\." => " ")) => "product_type")
knead.tool .= "KneadData"

#-
metap = DataFrame(path   = readdir("output/metaphlan/", join=true))
metap.file = basename.(metap.path)
transform!(metap, "file"=>  ByRow(f-> join(split(f, "_")[1:3], "_"))=> "sequence_id")
transform!(metap, "file"=>  ByRow(f-> join(split(f, "_")[1:2], "_"))=> "sample_id")
transform!(metap, "sequence_id"=> ByRow(f-> last(split(f, "_")))=> "well_id")

transform!(metap, "file" => ByRow(f-> begin
    contains(f, "bowtie2") && return "bowtie2 alignment table"
    contains(f, ".sam") && return "bowtie2 alignments"
    contains(f, "profile") && return "taxonomic profile"
end) => "product_type")
metap.tool .= "MetaPhlAn"

#-
humann = DataFrame(path  = [readdir("output/humann/main/", join=true);
                           readdir("output/humann/regroup/", join=true);
                           readdir("output/humann/rename/", join=true)]
)
humann.file = basename.(humann.path)

transform!(humann, "file"=>  ByRow(f-> join(split(f, "_")[1:3], "_"))=> "sequence_id")
transform!(humann, "file"=>  ByRow(f-> join(split(f, "_")[1:2], "_"))=> "sample_id")
transform!(humann, "sequence_id"=> ByRow(f-> last(split(f, "_")))=> "well_id")

transform!(humann, "file" => ByRow(f-> begin
    if contains(f, "rename")
        contains(f, "_kos_") && return "Kegg profile with names"
        contains(f, "_ecs_") && return "Enzyme commission profile with names"
        contains(f, "_pfams_") && return "Protein families profile with names"
    elseif contains(f, r"_(kos|ecs|pfams)_")
        contains(f, "_kos_") && return "Kegg profile"
        contains(f, "_ecs_") && return "Enzyme commission profile"
        contains(f, "_pfams_") && return "Protein families profile"
    else
        contains(f, "genefamilies") && return "UniRef90 profile"
        contains(f, "pathabundance") && return "Pathways profile"
        contains(f, "pathcoverage") && return "Pathways coverage profile"
    end
end) => "product_type")
humann.tool .= "HUMAnN"

#-
CSV.write("brainrise_files.csv", vcat(knead, metap, humann))
