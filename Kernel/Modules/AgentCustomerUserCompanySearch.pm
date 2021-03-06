# --
# Kernel/Modules/AgentCustomerUserCompanySearch.pm - a module used for the autocomplete feature
# Copyright (C) 2006-2016 c.a.p.e. IT GmbH, http://www.cape-it.de
#
# written/edited by:
# * Martin(dot)Balzarek(at)cape(dash)it(dot)de
# * Torsten(dot)Thau(at)cape(dash)it(dot)de
# * Anna(dot)Litvinova(at)cape(dash)it(dot)de
# * Mario(dot)Illinger(at)cape(dash)it(dot)de
# * Andreas(dot)Hergert(at)cape(dash)it(dot)de
# * Stefan(dot)Mehlig(at)cape(dash)it(dot)de
#
# --
# $Id: AgentCustomerUserCompanySearch.pm,v 1.12 2016/01/14 10:41:33 smehlig Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AgentCustomerUserCompanySearch;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::CustomerCompany',
    'Kernel::System::CustomerUser',
    'Kernel::System::Encode',
    'Kernel::System::Web::Request'
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    $Self->{ConfigObject}          = $Kernel::OM->Get('Kernel::Config');
    $Self->{LayoutObject}          = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    $Self->{CustomerCompanyObject} = $Kernel::OM->Get('Kernel::System::CustomerCompany');
    $Self->{CustomerUserObject}    = $Kernel::OM->Get('Kernel::System::CustomerUser');
    $Self->{EncodeObject}          = $Kernel::OM->Get('Kernel::System::Encode');
    $Self->{ParamObject}           = $Kernel::OM->Get('Kernel::System::Web::Request');

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $JSON = '';

    # get needed params
    my $Search = $Self->{ParamObject}->GetParam( Param => 'Term' ) || '';

    my $AutoCompleteConfig = $Self->{ConfigObject}->Get('AutoComplete::Agent')->{CustomerSearch};

    my $MaxResults = $AutoCompleteConfig->{MaxResultsDisplayed} || 20;

    my @CustomerIDs = $Self->{CustomerUserObject}->CustomerIDList(
        SearchTerm => $Search || '',
    );

    my %CustomerCompanyList = $Self->{CustomerCompanyObject}->CustomerCompanyList(
        Search => $Search || '',
    );

    # add CustomerIDs for which no CustomerCompany are registered
    my %Seen;
    for my $CustomerID (@CustomerIDs) {

        # skip duplicates
        next CUSTOMERID if $Seen{$CustomerID};
        $Seen{$CustomerID} = 1;

        # identifies unknown companies
        if ( !exists $CustomerCompanyList{$CustomerID} ) {
            $CustomerCompanyList{$CustomerID} = $CustomerID;
        }

    }

    # build result list
    my @Result;
    CUSTOMERID:
    for my $CustomerID ( sort keys %CustomerCompanyList ) {
        push @Result,
            {
            CustomerUserCompanyKey   => $CustomerID,
            CustomerUserCompanyValue => $CustomerCompanyList{$CustomerID},
            };
        last CUSTOMERID if scalar @Result >= $MaxResults;
    }

    # build JSON output
    $JSON = $Self->{LayoutObject}->JSONEncode(
        Data => \@Result,
    );

    # send JSON response
    return $Self->{LayoutObject}->Attachment(
        ContentType => 'application/json; charset=' . $Self->{LayoutObject}->{Charset},
        Content     => $JSON || '',
        Type        => 'inline',
        NoCache     => 1,
    );
}

1;
