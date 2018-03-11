# Fractal file generator for Mandelbulber2 using data from monero's blockchain as seed
# by garytheasshole and KnifeOfPi

use warnings;
use strict;
use 5.014;
use LWP::UserAgent();
use JSON qw( decode_json );

# Run your own blockchain explorer on your local monero blockchain to avoid trashing xmrchain.net and pull blocks much faster
# See https://github.com/moneroexamples/onion-monero-blockchain-explorer then change this variable to localhost/local ip
my $bc_explorer = "xmrchain.net";

sub generate_surface_color_palette {
   
    my ($seed, $size) = @_;
    my ($surface_color_palette, $foo);
    srand($seed);
    for (1..($size+2)) {
 
        $foo .= sprintf("%x", rand 16) for 1..6;
        $surface_color_palette .= "$foo ";
        undef $foo;
 
    }
    chop($surface_color_palette); # for that extra space at the end
    return $surface_color_palette;
}


my $height = shift or die "Usage: perl $0 height <debug>\n";
my $debug = shift;
my $ua = LWP::UserAgent->new;

my $response = $ua->get("http://".$bc_explorer."/api/block/".$height);
my $decoded = decode_json($response->content);

print "Raw content response for $height is\n\n". $response->content ."\n\n" if $debug;
print "Blockhash for $height is  $decoded->{'data'}{'hash'} \n" if $debug;

my $blockhash = $decoded->{'data'}{'hash'} 
or die "Something went terribly bad cannot fetch blockhash with height: $height\n";

print "Coinbase hash for $height block $blockhash is $decoded->{'data'}{'txs'}[0]{'tx_hash'} \n" if $debug;


my $coinbase_hash = $decoded->{'data'}{'txs'}[0]{'tx_hash'} 
or die "Something went terribly bad cannot fetch coinbase hash for $blockhash with height: $height\n";

my $main_light_intensity = $decoded->{'data'}{'txs'}[0]{'xmr_outputs'} / 1000000000000 
or die "Something went terribly bad cannot fetch block reward for $blockhash with height: $height\n";
print "The block reward for block $height is $main_light_intensity\n" if $debug;
$main_light_intensity /= 12;

my $txnum = scalar(@{$decoded->{'data'}{'txs'}}) - 1;
print "The number of transactions is ".$txnum."\n" if $debug;

for (1..scalar(@{$decoded->{'data'}{'txs'}})-1) {

    print "Transaction number $_ has hash " . $decoded->{'data'}{'txs'}[$_]{'tx_hash'}  
    ."and has a fee ".  $decoded->{'data'}{'txs'}[$_]{'tx_fee'} / 1000000000000 ."\n" if $debug;
}
 
my $tx_hash1 = $decoded->{'data'}{'txs'}[1]{'tx_hash'} if $decoded->{'data'}{'txs'}[1]{'tx_hash'};
my $tx_hash2 = $decoded->{'data'}{'txs'}[2]{'tx_hash'} if $decoded->{'data'}{'txs'}[2]{'tx_hash'};
my $tx_hash3 = $decoded->{'data'}{'txs'}[3]{'tx_hash'} if $decoded->{'data'}{'txs'}[3]{'tx_hash'};
my $tx_hash4 = $decoded->{'data'}{'txs'}[4]{'tx_hash'} if $decoded->{'data'}{'txs'}[4]{'tx_hash'};
my $tx_hash5 = $decoded->{'data'}{'txs'}[5]{'tx_hash'} if $decoded->{'data'}{'txs'}[5]{'tx_hash'}; # for random lights generation
 
my $tx_fee1 = $decoded->{'data'}{'txs'}[1]{'tx_fee'} / 1300000000000 if $decoded->{'data'}{'txs'}[1]{'tx_fee'};
my $tx_fee2 = $decoded->{'data'}{'txs'}[2]{'tx_fee'} / 1300000000000 if $decoded->{'data'}{'txs'}[2]{'tx_fee'};
my $tx_fee3 = $decoded->{'data'}{'txs'}[3]{'tx_fee'} / 1300000000000 if $decoded->{'data'}{'txs'}[3]{'tx_fee'}; # normalize fees
my $tx_fee4 = $decoded->{'data'}{'txs'}[4]{'tx_fee'} / 1300000000000 if $decoded->{'data'}{'txs'}[4]{'tx_fee'};
 
my ($is1, $is2, $is3, $is4) = ("false") x 4;
$is1 = "true" if $tx_hash1;
$is2 = "true" if $tx_hash2;
$is3 = "true" if $tx_hash3;
$is4 = "true" if $tx_hash4;

my $seed_palette = substr($blockhash, 0, 6);
$seed_palette = sprintf("%d", hex($seed_palette));
 
my $bg_color1 = substr($blockhash, 10, 6);
my $bg_color2 = substr($blockhash, 16, 6); # keep in hex
my $bg_color3 = substr($blockhash, 22, 6);
$bg_color1 =~ s/..\K(?=.)/00 /sg;
$bg_color1 .= "00";
 
$bg_color2 =~ s/..\K(?=.)/00 /sg;
$bg_color2 .= "00";
 
$bg_color3 =~ s/..\K(?=.)/00 /sg;
$bg_color3 .= "00";
 

 
my $palette_size = substr($blockhash, 28, 2);
$palette_size = sprintf("%d", hex($palette_size));
 
my $color_speed = substr($blockhash, 30, 1); # add 3 later
$color_speed = sprintf("%d", hex($color_speed));
$color_speed = $color_speed + 3;
 
my $palette_offset = substr($blockhash, 31, 2);
$palette_offset = sprintf("%d", hex($palette_offset));
 
my $scale = substr($blockhash, 33, 2); # divide 256 and add 1.5 later
$scale = sprintf("%d", hex($scale));
$scale = ($scale / 256) + 1.5;
 
my $x_vector_offset = substr($blockhash, 35, 2); # divide 512 and add 0.75 later
$x_vector_offset = sprintf("%d", hex($x_vector_offset));
$x_vector_offset = ($x_vector_offset / 512 ) + 0.75;
 
my $y_vector_offset = substr($blockhash, 37, 2); # if < 7f divide by 512 else by 128 127
$y_vector_offset = sprintf("%d", hex($y_vector_offset));
$y_vector_offset < 127 ? ($y_vector_offset /=  512) : ($y_vector_offset /= 128);
 
my $z_vector_offset = substr($blockhash, 39, 2); # divide by 256 and subtract 0.25
$z_vector_offset = sprintf("%d", hex($z_vector_offset));
$z_vector_offset = ($z_vector_offset / 256) - 0.25;
 
my $alpha_rotation = substr($blockhash, 41, 2); # divide by 16 and subtract 8
$alpha_rotation = sprintf("%d", hex($alpha_rotation));
$alpha_rotation = ($alpha_rotation / 16) - 8;
 
my $beta_rotation = substr($blockhash, 43, 2); # divide by 16 and subtract 8
$beta_rotation = sprintf("%d", hex($beta_rotation));
$beta_rotation = ($beta_rotation / 16) - 8;
 
my $gama_rotation = substr($blockhash, 45, 2); # divide by 16 and subtract 8
$gama_rotation = sprintf("%d", hex($gama_rotation));
$gama_rotation = ($gama_rotation / 16) - 8;
 
my $y_box_fold = substr($blockhash, 51, 4); # divide by 262144 and add 0.5
$y_box_fold = sprintf("%d", hex($y_box_fold));
$y_box_fold = ($y_box_fold / 262144) + 0.5;

my $rlights_seed = 1;
my ($rlights_dx, $rlights_dy, $rlights_dz) = (0) x 3;
my $rlights_num = ($txnum - 4);
my $rlights = "false";

if ($tx_hash5) {

    $rlights_seed = substr($tx_hash5, 0, 4);
    $rlights_seed = sprintf("%d", hex($rlights_seed));
    $rlights_dx = substr($tx_hash5, 4, 4);
    $rlights_dx = sprintf("%d", hex($rlights_dx));
    $rlights_dx = ($rlights_dx / 32768) - 1;
    $rlights_dy = substr($tx_hash5, 8, 4);
    $rlights_dy = sprintf("%d", hex($rlights_dy));
    $rlights_dy = ($rlights_dx / 32768) - 1;
    $rlights_dz = substr($tx_hash5, 12, 4);
    $rlights_dz = sprintf("%d", hex($rlights_dz));
    $rlights_dz = ($rlights_dx / 32768) - 1;
    $rlights = "true";
}

my $lights_enabled = "false";
$lights_enabled = "true" if $tx_hash5;


 
my $fold_and_rotation_byte =  substr($blockhash, 63, 1); # if 0-3 use nothing if 4-7 use $y_box_fold if 8-11 use *_rotations 12-15 nothing
 
my ($use_nothing, $use_y_box_fold, $use_rotations, $whattouse);
 
$fold_and_rotation_byte = sprintf("%d", hex($fold_and_rotation_byte));
$fold_and_rotation_byte = 16;
 
$use_nothing = 0;
$use_nothing = 1 if ( $fold_and_rotation_byte <= 3 );
$use_y_box_fold = 0;
$use_y_box_fold = 1 if ( $fold_and_rotation_byte <= 7 && $fold_and_rotation_byte > 3);
$use_rotations = 0;
$use_rotations = 1 if ( $fold_and_rotation_byte <= 11 && $fold_and_rotation_byte > 7);
$use_nothing = 1 if ( $fold_and_rotation_byte <= 15 && $fold_and_rotation_byte > 11);
 
$whattouse = 0;
$whattouse = $y_box_fold if ( $use_y_box_fold == 1 );
$whattouse = $fold_and_rotation_byte if ( $use_rotations == 1 );
 
my $truefalse = $use_nothing == 1 ? "false" : "true";
 
my $main_light_color = substr($coinbase_hash, 0, 6);
$main_light_color =~ s/..\K(?=.)/00 /sg;
$main_light_color .= "00";
 
my ($x_light_position, $x_light_position2, $x_light_position3, $x_light_position4) = (" ") x 4;
my ($y_light_position, $y_light_position2, $y_light_position3, $y_light_position4) = (" ") x 4;
my ($z_light_position, $z_light_position2, $z_light_position3, $z_light_position4) = (" ") x 4;
my ($brightness, $brightness2, $brightness3, $brightness4) = (" ") x 4;
my ($color, $color2, $color3, $color4) = (" ") x 4;


if ($tx_hash1) {

    $x_light_position = (substr($tx_hash1, 0, 4));
    $x_light_position  = sprintf("%d", hex($x_light_position));
    $x_light_position = ($x_light_position / 32768) - 1;
 
    $y_light_position = (substr($tx_hash1, 4, 4));
    $y_light_position  = sprintf("%d", hex($y_light_position));
    $y_light_position = ($y_light_position / 32768) - 1;

    $z_light_position = (substr($tx_hash1, 8, 4));
    $z_light_position  = sprintf("%d", hex($z_light_position));
    $z_light_position = ($z_light_position / 32768) - 1;
   
    $color = (substr($tx_hash1, 12, 6));
    $color =~ s/..\K(?=.)/00 /sg;
    $color .= "00";
 
    $brightness = $tx_fee1 * 10;
}

if ($tx_hash2) {

    $x_light_position2 = (substr($tx_hash2, 0, 4));
    $x_light_position2  = sprintf("%d", hex($x_light_position2));
    $x_light_position2 = ($x_light_position2 / 32768) - 1;
 
    $y_light_position2 = (substr($tx_hash2, 4, 4));
    $y_light_position2  = sprintf("%d", hex($y_light_position2));
    $y_light_position2 = ($y_light_position2 / 32768) - 1;
 
    $z_light_position2 = (substr($tx_hash2, 8, 4));
    $z_light_position2  = sprintf("%d", hex($z_light_position2));
    $z_light_position2 = ($z_light_position2 / 32768) - 1;
 
    $color2 = (substr($tx_hash2, 12, 6));
    $color2 =~ s/..\K(?=.)/00 /sg;
    $color2 .= "00";
 
    $brightness2 = $tx_fee2 * 10; # * 10
} 

if ($tx_hash3) {

    $x_light_position3 = (substr($tx_hash3, 0, 4));
    $x_light_position3  = sprintf("%d", hex($x_light_position3));
    $x_light_position3 = ($x_light_position3 / 32768) - 1;
 
    $y_light_position3 = (substr($tx_hash3, 4, 4));
    $y_light_position3  = sprintf("%d", hex($y_light_position3));
    $y_light_position3 = ($y_light_position3 / 32768) - 1;
 
    $z_light_position3 = (substr($tx_hash3, 8, 4));
    $z_light_position3  = sprintf("%d", hex($z_light_position3));
    $z_light_position3 = ($z_light_position3 / 32768) - 1;
 
    $color3 = (substr($tx_hash3, 12, 6));
    $color3 =~ s/..\K(?=.)/00 /sg;
    $color3 .= "00";
 
    $brightness3 = $tx_fee3 * 10; # * 10
}
 
if ($tx_hash4) {

    $x_light_position4 = (substr($tx_hash4, 0, 4));
    $x_light_position4  = sprintf("%d", hex($x_light_position4));
    $x_light_position4 = ($x_light_position4 / 32768) - 1;
 
    $y_light_position4 = (substr($tx_hash4, 4, 4));
    $y_light_position4  = sprintf("%d", hex($y_light_position4));
    $y_light_position4 = ($y_light_position4 / 32768) - 1;
 
    $z_light_position4 = (substr($tx_hash3, 8, 4));
    $z_light_position4  = sprintf("%d", hex($z_light_position4));
    $z_light_position4 = ($z_light_position4 / 32768) - 1;
 
    $color4 = (substr($tx_hash4, 12, 6));
    $color4 =~ s/..\K(?=.)/00 /sg;
    $color4 .= "00";
 
    $brightness4 = $tx_fee4 * 10;
}

my $camera_pos = "0.5657031888468234 -2.764463391368074 0.4975508102106437";
my $camera_top = "-0.03481289900076248 0.1701227547102634 0.9848077530122081";
my $camera_rot = "11.56500000000002 -9.999999999999989 0";
my $camera_tar = "2.865280919705257";

if ($height >= 1009827 && $height < 1141317) {

    $camera_pos = "2.219438048054018 1.109716546001921 1.432640459852628";
    $camera_top = "-0.4547451154264854 -0.2078626469468535 0.8660254037844389";
    $camera_rot = "114.565 -29.99999999999996 0";

}

if ($height >= 1141317 && $height < 1220516) {

    $camera_pos = "-0.8044893775961957 2.704639491950941 -0.4975508102106453";
    $camera_top = "-0.04366872617903531 0.1680676410286832 0.9848077530122085";
    $camera_rot = "-165.435 9.999999999999989 0";

}

if ($height >= 1220516 && $height < 1288616) {

    $camera_pos = "1.122234136839151 2.588989857492427 0.4975508102106437";
    $camera_top = "-0.0690613460048356 -0.1593242608488931 0.9848077530122086";
    $camera_rot = "156.5650000000001 -9.999999999999989 0";

}

if ($height >= 1288616 && $height < 1400000) {

    $camera_pos = "-1.31799790913125 -2.210033361161712 1.260344715903144";
    $camera_top = "0.2253009707652209 0.3777871408168339 0.8980625528356535";
    $camera_rot = "-30.81058841234304 -26.09544436694554 0";

}

if($height >= 1400000 && $height < 1539500) {

    $camera_pos = "2.834443203877877 -0.2884414684974628 0.3042498842540278";
    $camera_top = "-0.1054357275300752 0.01259221162347292 0.9943463901310416";
    $camera_rot = "83.18941158765709 -6.095444366945558 0";

}

if($height >= 1539500 ) {

    $camera_pos = "-1.787317448728921 1.787317448728921 1.787317448728921";
    $camera_top = "0.4082482903528664 -0.4082482903528663 0.8164965810387228";
    $camera_rot = "-135 -35.26438967173943 0";

}
 
my $gen = generate_surface_color_palette($seed_palette, $palette_size);
my $fractal_file = <<"END";
# Mandelbulber settings file
# version 2.11
# only modified parameters
[main_parameters]
ambient_occlusion 0.5; # static
ambient_occlusion_enabled true; # static
fov 1.75;
aux_light_colour_1 $color; # FROM 6 BYTES OF TX 1
aux_light_colour_2 $color2; # FROM 6 BYTES OF TX 2
aux_light_colour_3 $color3;; # FROM 6 BYTES OF TX 3
aux_light_colour_3 $color4; # FROM 6 BYTES OF TX 4
aux_light_enabled_1 $is1; # FALSE IF NUM OF NON-COINBASE TX < 1
aux_light_enabled_2 $is2; # FALSE IF NUM OF NON-COINBASE TX < 2 # blockchain voodoo later
aux_light_enabled_3 $is3; # FALSE IF NUM OF NON-COINBASE TX < 3
aux_light_enabled_4 $is4; # FALSE IF NUM OF NON-COINBASE TX < 4
aux_light_intensity_1 $brightness; # BRIGHTNESS
aux_light_intensity_2 $brightness2; # BRIGHTNESS
aux_light_intensity_3 $brightness3; # BRIGHTNESS
aux_light_intensity_4 $brightness4; # BRIGHTNESS
aux_light_position_1 $x_light_position $y_light_position $z_light_position; # X POSITION OF LIGHT Y POSITION OF LIGHT Z POSITION OF LIGHT
aux_light_position_2 $x_light_position2 $y_light_position2 $z_light_position2; # X POSITION OF LIGHT Y POSITION OF LIGHT Z POSITION OF LIGHT
aux_light_position_3 $x_light_position3 $y_light_position3 $z_light_position3; # X POSITION OF LIGHT Y POSITION OF LIGHT Z POSITION OF LIGHT
aux_light_position_4 $x_light_position4 $y_light_position4 $z_light_position4; # X POSITION OF LIGHT Y POSITION OF LIGHT Z POSITION OF LIGHT
aux_light_visibility_size 0.13; # static
background_color_1 $bg_color1; # BACKGROUND COLOR 1 'e982a1'
background_color_2 $bg_color1; # BACKGROUND COLOR 2 '975da7'
background_color_3 $bg_color1; # BACKGROUND COLOR 3 'c79277'
basic_fog_color $bg_color1; # static
basic_fog_enabled true;
basic_fog_visibility 900; # static
camera $camera_pos;
camera_distance_to_target $camera_tar;
camera_rotation $camera_rot;
camera_top $camera_top;
DE_factor 1; # static
DE_thresh 0.0025; # static
delta_DE_function 2; # static
detail_level 1.25;
flight_last_to_render 0; # static
formula_1 10; # static
image_height 1024; # static
image_width 1024; # static
keyframe_last_to_render 0; # static
main_light_colour $main_light_color; # MAIN LIGHT COLOR '0d91c9'
main_light_intensity $main_light_intensity; # FROM COINBASE TX VALUE # blockchain magic?
mat1_coloring_palette_offset $palette_offset; # 2 bytes '05'
mat1_coloring_palette_size $palette_size; # 2 bytes 'c2'
mat1_coloring_random_seed 61976; # static
mat1_coloring_speed $color_speed; # 1 byte, '7'
mat1_is_defined true; # static
mat1_surface_color_palette $gen; # GENERATE USING FIRST 6 BYTES OF BLOCKHASH AS SEED. LENGTH IS mat1_coloring_palette_size
random_lights_distribution_center $rlights_dx $rlights_dy $rlights_dz;
random_lights_distribution_radius 4;
random_lights_group $rlights;
random_lights_intensity 0.6;
random_lights_max_distance_from_fractal 0.6;
random_lights_number $rlights_num;
random_lights_random_seed $rlights_seed;
view_distance_max 1150;  # static
repeat 8 8 8;
[fractal_1]
IFS_abs_x true; # static
IFS_abs_y true; # static
IFS_abs_z true; # static
IFS_direction_5 1 -1 0; # static
IFS_direction_6 1 0 -1; # static
IFS_direction_7 0 1 -1; # static
IFS_edge 0 $whattouse 0; # SECOND VALUE IS Y BOX FOLD ('daab'). if byte ('3') from the 'nothing, y_box_fold, rotations, nothing' isn't set to y_box_fold, this is zero
IFS_edge_enabled true; #or you could set this to true/false depending on this value
IFS_enabled_5 true; # static
IFS_enabled_6 true; # static
IFS_enabled_7 true; # static
IFS_offset $x_vector_offset $y_vector_offset $z_vector_offset; #X VECTOR OFFSET Y VECTOR OFFSET Z VECTOR OFFSET
IFS_rotation $alpha_rotation $beta_rotation $gama_rotation; #ALPHA ROTATION BETA ROTATION GAMMA ROTATION (4b a0 fb)
IFS_rotation_enabled $truefalse; #set to false if the byte '3' isn't 8-B
IFS_scale $scale; #SCALE '72'
END
 
my $filename = $height.".fract";
open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
print $fh $fractal_file;
close $fh;
print "done\n";
