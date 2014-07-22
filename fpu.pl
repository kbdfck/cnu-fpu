#!/usr/bin/perl
#Cisco CNU_File_Archive_3.0 firmware packer/unpacker
#Written by kbdfck, 2007, 2009
#http://virtualab.ru

use strict;
use warnings;

use Getopt::Long;

my $CNU_SIGNATURE="CNU_File_Archive_3.0";

my $SIGN_LEN = length($CNU_SIGNATURE);
my $HDR_HOLE1_LEN = 0x1C; #Zerofill in header
my $HDR_HOLE2_LEN = 0x1FC; #Zerofill in header
my $FT_OFFSET = 0x248; #Filetable offset
my $HDR_LEN = $FT_OFFSET; #Header length
my $FT_REC_LEN = 0x14; #Filetable record length

my $quiet; #Don't print information messages


#Service functions
sub usage {
	print STDERR "Usage: $0 --unpack --input-file=unsigned_firmware_file [ --output-dir=unpacked_firmware_dir ]\n";
	print STDERR "Usage: $0 --pack --input-dir=/unpacked/firmware/dir --output-file=cool_repacked_firmware_file\n";
	print STDERR "Default output dir is input_file-unpacked\n";
}

sub error {
	$quiet || printf STDERR "Error: ".shift()."\n", @_;
}

sub notice {
	$quiet || printf STDERR shift()."\n", @_;
}

sub get_options {
	my $opts = {};
unless(GetOptions($opts, "unpack", "pack", "quiet", "help", "input-file=s", "output-file=s", "input-dir=s", "output-dir=s" )) {
		error "Incorrect options";
		usage();
		exit(255);
	}

	$quiet = exists $opts->{'quiet'};

	return $opts;
}

### Option checkers

sub check_unpack_opts {
	my $opts = shift;

	#Now Getopt::Long handles this
	unless ($opts->{'input-file'}) {
		error("You should specify input file with --input-file");
		exit(255);
	}

	unless ($opts->{'output-dir'}) {
		notice("No --output-dir specified, assuming ./%s-unpacked",$opts->{'input-file'});
		$opts->{'output-dir'} = "./".$opts->{'input-file'}."-unpacked";
	} else {
		#To check or not to check?
	}
}

sub check_pack_opts {
	my $opts = shift;

	unless ($opts->{'input-dir'}) {
		notice('You should specify input dir with --input-dir');
	} else {
		#To check or not to check?
	}

	#Now Getopt::Long handles this
	unless ($opts->{'output-file'}) {
		error('You should specify output file with --output-file');
		exit(255);
	}

}



### File/directory routines
sub file_mkpath {
	my $fn = $_[0];
	my ($orig_path) = $fn =~ m#^(.*/).*#;	
	$orig_path = '.' unless $orig_path;
	$orig_path =~ s#/+#/#g; #Kill repeated /
	$orig_path =~ s{/$}{}; 
	my $path;
	foreach(split(/\//,$orig_path)) {
		unless ($_) {
			$path .= '/';
			next;
		}

		$path .= $_;
		unless( -d $path) {
			mkdir ($path) || return (0, "mkdir $path - $!");	
		};
		$path .= '/';
	}

	return 1;
}

sub read_file {
	my $fn = $_[0];
	open(IF, '<', $fn) || return (undef, 0, $!);
	my $buffer;
	my $content;
	while(read(IF, $buffer,16384)) {
		$content .= $buffer;	
	}
	close(IF);
	return ($content, 1, undef);
}

sub write_file {
	my ($fn, $content) = @_;	
	my ($status, $error_msg) = file_mkpath($fn);

	return ($status, $error_msg) unless $status;
		
	open(F, '>', $fn) || return (0, $!);
	binmode(F);
	print F $content;	
	close(F);
	
	
	return 1;
}

#Loads files' content and metadata from specified directory and subdirectories
#Filenames are absolute paths using specified directory as root

#sub load_dir {	
#Actually, this should be implemented as depth-order traversal

#	my $path = $_[0];
#	my $fw_path = '';

#	my @dir_list = ('/'); #Initial dir is a path itself
#	my @files;
	
#	my $dir;
#	while (defined ($dir = shift(@dir_list))) {
#		my $dh;
#		$fw_path = $dir;
		
#		opendir($dh, "$path$fw_path") || return (undef, 0, $!);
#		my @dir_content = readdir($dh);
#		closedir($dh);

#		my @cur_dir_files = grep { -f "$path$fw_path/$_" } @dir_content;
#		my @cur_dir_subdirs = grep { !/^\.{1,2}/ && -d "$path$fw_path$_" } @dir_content;
#		push @dir_list, map { "$fw_path$_/"} @cur_dir_subdirs;

#		foreach(@cur_dir_files) {
#			my $file = {};
#			$file->{'name'} = "$fw_path$_";

#			my ($status, $error_msg);
#			($file->{'content'}, $status, $error_msg) = read_file($path.$file->{'name'});
#			unless ($status) {
#				notice("Failed to load %s: %s", $file->{'name'}, $error_msg);
#				return (undef, 0, "Failed to load dir: $dir");
#			}
		
#			notice("Loaded %s", $file->{'name'});
#			($file->{'size'}, $file->{'timestamp'}) = (stat $path.$file->{'name'})[7,9];
#			push(@files, $file);
#		}
#	}

#	return (\@files, 1, undef);	
#}

sub load_dir {	

	my $path = $_[0];
	my $fw_path = $_[1];
	my @files;
	my $dh;
	
	opendir($dh, "$path") || return (undef, 0, $!);
		my @dir_content = readdir($dh);
	closedir($dh);

	my @dir_files = grep { -f "$path/$_" } @dir_content;
	my @dir_subdirs = grep { !/^\.{1,2}/ && -d "$path/$_" } @dir_content;

	foreach(@dir_files) {
		my $file = {};
		$file->{'name'} = "$fw_path$_";

		my ($status, $error_msg);
		($file->{'content'}, $status, $error_msg) = read_file("$path/$_");
		unless ($status) {
			notice("Failed to load %s: %s", $file->{'name'}, $error_msg);
			return (undef, 0, "Failed to load dir: $path");
		}
		
		notice("Loaded %s", $file->{'name'});
		($file->{'size'}, $file->{'timestamp'}) = (stat $path."/".$_)[7,9];
		push(@files, $file);
	}

	foreach(@dir_subdirs) {
		my ($subdir_files, $status, $msg)  = load_dir($path."/".$_, $fw_path.$_."/");
	   	return (undef, 0, "Failed to read dir: $path/$_: $msg") unless $status;

		push(@files, @{ $subdir_files } );
	}

	return (\@files, 1, undef);	
}



### Unpack routines

sub read_fw_file_table { 
	my ($content, $header) = @_;

	my @recs;
	my $num_raw_files = 0; #Special files counter for correct naming in case if there are many such files
	my $cur_offset = 0; #Current offset to calculate each file content offset
	my $i;
	for( $i = 0; $i < $header->{'num_files'}; $i++) {
		my $chunk = substr($content, $FT_OFFSET + $i*$FT_REC_LEN, $FT_REC_LEN);
		my @f_fields = unpack( "N5", $chunk);
		my $file_rec = {};
		( 	$file_rec->{'f1'}, 
			$file_rec->{'f2'}, 
			$file_rec->{'size'}, 
			$file_rec->{'timestamp'}, 
			$file_rec->{'filename_offset'} 
		) = @f_fields;
			
		#unpack("Z" does the trick?
		if ($file_rec->{'f1'} == 7) {
			$file_rec->{'name'} = substr($content, $file_rec->{'filename_offset'}, 
				index($content,"\x00",$file_rec->{'filename_offset'}) - $file_rec->{'filename_offset'});
		} else {
			$num_raw_files++;
			$file_rec->{'name'} = '/.raw'.$num_raw_files;	
		}
		$file_rec->{'content_offset'} = $header->{'content_offset'} + $cur_offset;
		$cur_offset += $file_rec->{'size'};
		push(@recs, $file_rec);
	}

	return \@recs;	
}

sub write_files {
	my ($content, $header, $ft, $base_dir) = @_;
	
	my $errors_found = 0;

	my $file;
	foreach $file (@{$ft}) {
		#Added slash to ensure that we don't leave target dir
		my ($status, $error) =  write_file(
			$base_dir.'/'.$file->{'name'}, 
			substr($content, $file->{'content_offset'}, $file->{'size'}),
			); 
		 
		if ($status) {
			utime($file->{'timestamp'}, $file->{'timestamp'}, $base_dir.'/'.$file->{'name'});
			notice("Extracted %s to %s",$file->{'name'}, $base_dir.$file->{'name'});
		} else {
			notice("Failed to write %s: %s",$file->{'name'}, $error);
			$errors_found++;
		}

	}

	return $errors_found;
}

sub fw_unpack {
	my $opts = shift;

	#Actually reading whole file in memory sucks
	my ($fw_content, $status, $error) = read_file($opts->{'input-file'});
	
	unless($status) {
		error("Can't read %s: %s", $opts->{'input-file'}, $error);
		return;	
	}

	#Seems to be a reasonable limit
	if ( length($fw_content) < 16384) {
		error("File is too small to be a Cisco firmware");
		return;
	}

	my @fields = unpack("A${SIGN_LEN}x${HDR_HOLE1_LEN}NN", substr($fw_content,0,$HDR_LEN));		
	
	my $header = {};
	$header->{'signature'} = $fields[0];
	$header->{'num_files'} = $fields[1];
	$header->{'content_offset'} = $fields[2];
	
	unless($header->{'signature'} eq $CNU_SIGNATURE) {
		error("CNU archive signature not found, exiting");
		return;
	}	

	my $file_table = read_fw_file_table($fw_content, $header);

	return write_files($fw_content, $header, $file_table, $opts->{'output-dir'});

}

sub fw_pack {
	my $opts = $_[0];
	my ($files, $ld_status, $ld_error) = load_dir($opts->{'input-dir'},'/');

	return ($ld_status, $ld_error) unless $ld_status;

	my $num_files = @{$files};
	my $ft_len = $num_files * $FT_REC_LEN; #Filetable size in bytes;
	my $cur_filename_offset = 0;

	my @ft;
	
	my $file;
	foreach $file (@{$files}) {
		my $ft_rec = {};

		if ($file->{'name'} =~ /\/.raw/) {
			#This is a raw data to be loaded directly 
			#Maybe loader code or smth like that
			#Store it with no filename, zero name offset and with specific type
			$ft_rec->{'f1'} = 6; #Some specific destination flag?
			$ft_rec->{'f2'} = 2; #is usual file? 
			$ft_rec->{'name'} = undef; 
			$ft_rec->{'filename_offset'} = 0; 
		} else {
			$ft_rec->{'f1'} = 7; #Some another destination (main flash?)
			$ft_rec->{'f2'} = 2; #usual file
			$ft_rec->{'name'} = $file->{'name'};
			$ft_rec->{'filename_offset'} = $HDR_LEN+$ft_len+$cur_filename_offset;	
			$cur_filename_offset += length($file->{'name'}) + 1;
		}
		
		$ft_rec->{'size'} = $file->{'size'};
		$ft_rec->{'timestamp'} = $file->{'timestamp'};
		#Calculate name list length to get content offset value for header and filename offset for filetable rec
		push @ft, $ft_rec;
	}	

	my $header = {};
	$header->{'signature'} = $CNU_SIGNATURE;
	$header->{'num_files'} = $num_files;
	$header->{'content_offset'} = $HDR_LEN+$ft_len+$cur_filename_offset;
	
	my $serialized_header = pack "A*x[$HDR_HOLE1_LEN]NNA*x[$HDR_HOLE2_LEN]", $header->{'signature'}, $header->{'num_files'}, $header->{'content_offset'},$header->{'signature'};

	my @serialized_ft_recs;
	my @serialized_filenames;

	foreach(@ft) {
		my $s_rec=  pack "NNNNN" ,  $_->{'f1'}, $_->{'f2'}, $_->{'size'}, $_->{'timestamp'}, $_->{'filename_offset'};
		push @serialized_ft_recs, $s_rec;
		#special files don't have names in firmware, add only usual ones
		if ($_->{'f1'} == 7) {
			my $s_filename =  pack "Z*", $_->{'name'} ;
			push @serialized_filenames, $s_filename;
		}
	}
	
		
	my ($mp_status, $mp_error) = file_mkpath($opts->{'output-file'});
	return ($mp_status, $mp_error) unless $mp_status;
		
	open(F, '>', $opts->{'output-file'}) || return (0, $!);
	binmode(F);

	print F $serialized_header;
	notice("Wrote header");
	print F join '', @serialized_ft_recs;
	notice("Wrote filetable: %i files", scalar @serialized_ft_recs);
	print F join '', @serialized_filenames;
	foreach( @{$files} ) {
		print F $_->{'content'} if defined $_->{'content'};	
	}
	notice("Wrote content");
	
	close(F);
	return 1;
}


### Main

my $opts = get_options();

if ($opts->{'unpack'}) {
	check_unpack_opts($opts);

	#fw_unpack returns number of errors during unpack or undef on fatal error
	my $num_errors = fw_unpack($opts); 
	defined $num_errors || exit(5);
	notice("Finished with %i error(s)", $num_errors);
	exit();
}

if ($opts->{'pack'}) {
	check_pack_opts($opts);
	
	my ($status, $error) = fw_pack($opts);
	if ($status) {
		notice("Firmware packed successfully to %s", $opts->{'output-file'});
	} else {
		error("Error while packing firmware: %s", $error);
	}
	exit();
}

usage();

