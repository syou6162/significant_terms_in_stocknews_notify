#!/usr/bin/env perl
use strict;
use warnings;
use Search::Elasticsearch;
use utf8;
use Encode;
use Unicode::Japanese;
use Scalar::Util qw/looks_like_number/;

my $e = Search::Elasticsearch->new(
    nodes => [ 'localhost:9200', ]
);

my $day = 1;

my $results = $e->search(
    index => 'stocknews',
    type => "news",
    body  => {
        "aggs" => {
            "range"=> {
                filter => {
                    range => {
                        date => {
                            gte => "now-" . $day . "d/d",
                            lte => "now",
                            time_zone => "+09:00",
                        },
                    },
                },
                "aggs" => {
                    terms => {
                        "significant_terms" => {
                            "field" => "content",
                            "size" => 50,
                        }
                    },
                },
            },
        },
    },
);

my $num = 0;

foreach my $bucket (@{$results->{aggregations}->{range}->{terms}->{buckets}}) {
    next if $num >= 10;
    my $term1 = decode_utf8 $bucket->{key};
    my $term2 = Unicode::Japanese->new($term1)->z2hNum->getu;
    my $term3 = Unicode::Japanese->new($term2)->z2hAlpha->getu;
    my $term4 = Unicode::Japanese->new($term3)->z2hSym->getu;
    next if looks_like_number $term4;
    my $line = $term4 . "(" . $bucket->{doc_count} . "件)\n";
    print encode_utf8 $line;
    $num++;
}
