#--
#Kernel/Output/HTML/ITSMConfigItemLayoutServiceReference.pm - layout backend module
# Copyright (C) 2006-2016 c.a.p.e. IT GmbH, http://www.cape-it.de
#
# written/changed by:
# * Stefan(dot)Mehlig(at)cape-it(dot)de
# * Torsten(dot)Thau(at)cape-it(dot)de
# * Frank(dot)Oberender(at)cape-it(dot)de
# * Anna(dot)Litvinova(at)cape(dash)it(dot)de
# * Mario(dot)Illinger(at)cape(dash)it(dot)de
# * Frank(dot)Jacquemin(at)cape-it(dot)de
#
#--
#$Id: LayoutServiceReference.pm,v 1.3 2016/05/27 13:23:06 fjacquemin Exp $
#--
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
#--

package Kernel::Output::HTML::ITSMConfigItem::LayoutServiceReference;

use strict;
use warnings;

our @ObjectDependencies = (
    'Kernel::Config',
    'Kernel::Language',
    'Kernel::Output::HTML::Layout',
    'Kernel::System::Log',
    'Kernel::System::Service',
    'Kernel::System::Web::Request'
);

=head1 NAME

Kernel::Output::HTML::ITSMConfigItemLayoutServiceReference - layout backend module

=head1 SYNOPSIS

All layout functions of ServiceReference objects

=over 4

=cut

=item new()

create an object

    use Kernel::System::ObjectManager;
    local $Kernel::OM = Kernel::System::ObjectManager->new();
    my $BackendObject = $Kernel::OM->Get('Kernel::Output::HTML::ITSMConfigItemLayoutServiceReference');

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{ConfigObject}   = $Kernel::OM->Get('Kernel::Config');
    $Self->{LanguageObject} = $Kernel::OM->Get('Kernel::Language');
    $Self->{LayoutObject}   = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    $Self->{LogObject}      = $Kernel::OM->Get('Kernel::System::Log');
    $Self->{ServiceObject}  = $Kernel::OM->Get('Kernel::System::Service');
    $Self->{ParamObject}    = $Kernel::OM->Get('Kernel::System::Web::Request');

    return $Self;
}

=item OutputStringCreate()

create output string

    my $Value = $BackendObject->OutputStringCreate(
        Value => 11,       # (optional)
    );

=cut

sub OutputStringCreate {
    my ( $Self, %Param ) = @_;

    #transform ascii to html...
    $Param{Value} = $Self->{LayoutObject}->Ascii2Html(
        Text => $Param{Value} || '',
        HTMLResultMode => 1,
    );

    return $Param{Value};
}

=item FormDataGet()

get form data as hash reference

    my $FormDataRef = $BackendObject->FormDataGet(
        Key => 'Item::1::Node::3',
        Item => $ItemRef,
    );

=cut

sub FormDataGet {
    my ( $Self, %Param ) = @_;

    #check needed stuff...
    for my $Argument (qw(Key Item)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!"
            );
            return;
        }
    }

    my %FormData;

    #get selected CIClassReference...
    $FormData{Value} = $Self->{ParamObject}->GetParam( Param => $Param{Key} );

    #check search button..
    if ( $Self->{ParamObject}->GetParam( Param => $Param{Key} . '::ButtonSearch' ) ) {
        $Param{Item}->{Form}->{ $Param{Key} }->{Search}
            = $Self->{ParamObject}->GetParam( Param => $Param{Key} . '::Search' );
    }

    #check select button...
    elsif ( $Self->{ParamObject}->GetParam( Param => $Param{Key} . '::ButtonSelect' ) ) {
        $FormData{Value} = $Self->{ParamObject}->GetParam( Param => $Param{Key} . '::Select' );
    }

    #check clear button...
    elsif ( $Self->{ParamObject}->GetParam( Param => $Param{Key} . '::ButtonClear' ) ) {
        $FormData{Value} = '';
    }
    else {

        #reset value if search field is empty...
        if (
            !$Self->{ParamObject}->GetParam( Param => $Param{Key} . '::Search' )
            && defined $FormData{Value}
            )
        {
            $FormData{Value} = '';
        }

        #check required option...
        if ( $Param{Item}->{Input}->{Required} && !$FormData{Value} ) {
            $Param{Item}->{Form}->{ $Param{Key} }->{Invalid} = 1;
            $FormData{Invalid} = 1;
        }
    }

    return \%FormData;
}

=item InputCreate()

create a input string

    my $Value = $BackendObject->InputCreate(
        Key => 'Item::1::Node::3',
        Value => 11,       # (optional)
        Item => $ItemRef,
    );

=cut

sub InputCreate {
    my ( $Self, %Param ) = @_;

    #check needed stuff...
    for my $Argument (qw(Key Item)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!"
            );
            return;
        }
    }

    my $Value = '';
    if ( defined $Param{Value} ) {
        $Value = $Param{Value};
    }
    elsif ( $Param{Item}->{Input}->{ValueDefault} ) {
        $Value = $Param{Item}->{Input}->{ValueDefault};
    }

    my $Size         = $Param{Item}->{Input}->{Size} || 50;
    my $Search       = '';
    my $StringOption = '';
    my $StringSelect = '';
    my $Class        = 'W50pc ServiceSearch';
    my $Required     = $Param{Required} || '';
    my $Invalid      = $Param{Invalid} || '';
    my $ItemId       = $Param{ItemId} || '';

    if ($Required) {
        $Class .= ' Validate_Required';
    }

    if ($Invalid) {
        $Class .= ' ServerError';
    }

    # ServiceReference search...
    if ( $Param{Item}->{Form}->{ $Param{Key} }->{Search} ) {

        #-----------------------------------------------------------------------
        # search for name....
        my @ServiceIDs = $Self->{ServiceObject}->ServiceSearch(
            Name   => '*' . $Param{Item}->{Form}->{ $Param{Key} }->{Search} . '*',
            UserID => 1,
        );
        my %ServiceList = ();
        for my $CurrKey (@ServiceIDs) {
            my %ServiceData = $Self->{ServiceObject}->ServiceGet(
                ServiceID => $CurrKey,
                UserID    => 1,
            );
            next if ( !%ServiceData );
            $ServiceList{$CurrKey}
                = $ServiceData{Name}
                . " ("
                . $CurrKey
                . ")";
        }

        #-----------------------------------------------------------------------
        # build search result presentation....
        if ( %ServiceList && scalar( keys %ServiceList ) > 1 ) {

            #create option list...
            $StringOption = $Self->{LayoutObject}->BuildSelection(
                Name => $Param{Key} . '::Select',
                Data => \%ServiceList,
            );
            $StringOption .= '<br>';

            #create select button...
            $StringSelect = '<input class="button" type="submit" name="'
                . $Param{Key}
                . '::ButtonSelect" '
                . 'value="'
                . $Self->{LanguageObject}->Translate( "Select" )
                . '">&nbsp;';

            #set search...
            $Search = $Param{Item}->{Form}->{ $Param{Key} }->{Search};
        }
        elsif (%ServiceList) {
            $Value = ( keys %ServiceList )[0];
            my %ServiceData = $Self->{ServiceObject}->ServiceGet(
                ServiceID => $Value,
                UserID    => 1,
            );
            my $ServiceName = "";

            if ( %ServiceData && $ServiceData{Name} ) {
                $ServiceName = $ServiceData{Name};
            }

            #transform ascii to html...
            $Search = $Self->{LayoutObject}->Ascii2Html(
                Text => $ServiceName || '',
                HTMLResultMode => 1,
            );
        }

    }

    #create CIClassReference string...
    elsif ($Value) {

        my %ServiceData = $Self->{ServiceObject}->ServiceGet(
            ServiceID => $Value,
            UserID    => 1,
        );
        my $ServiceName = "";

        if ( %ServiceData && $ServiceData{Name} ) {
            $ServiceName = $ServiceData{Name};
        }

        #transform ascii to html...
        $Search = $Self->{LayoutObject}->Ascii2Html(
            Text => $ServiceName || '',
            HTMLResultMode => 1,
        );
    }

    # AutoComplete CIClass
    my $AutoCompleteConfig
        = $Self->{ConfigObject}->Get('ITSMCIAttributeCollection::Frontend::CommonSearchAutoComplete');

    #create string...
    my $String = '';
    if (   $AutoCompleteConfig
        && ref($AutoCompleteConfig) eq 'HASH'
        && $AutoCompleteConfig->{Active} )
    {

        $Self->{LayoutObject}->Block(
            Name => 'ServiceSearchAutoComplete',
            Data => {
                minQueryLength      => $AutoCompleteConfig->{MinQueryLength}      || 2,
                queryDelay          => $AutoCompleteConfig->{QueryDelay}          || 0.1,
                typeAhead           => $AutoCompleteConfig->{TypeAhead}           || 'false',
                maxResultsDisplayed => $AutoCompleteConfig->{MaxResultsDisplayed} || 20,
                dynamicWidth        => $AutoCompleteConfig->{DynamicWidth}        || 1,
            },
        );
        $Self->{LayoutObject}->Block(
            Name => 'ServiceSearchInit',
            Data => {
                ItemID             => $ItemId,
                ActiveAutoComplete => 'true',
                }
        );

        $String = $Self->{LayoutObject}->Output(
            TemplateFile => 'AgentServiceSearch',
        );
        $String
            = '<input type="hidden" name="'
            . $Param{Key}
            . '" value="'
            . $Value
            . '" id="'
            . $ItemId . 'Selected'
            . '"/>'
            . '<input type="text" name="'
            . $Param{Key}
            . '::Search" class="'
            . $Class
            . '" id="'
            . $ItemId
            . '" SearchClass="'
            . 'ServiceSearch'
            . '" value="'
            . $Search . '"/>';
    }
    else {
        $String
            = '<input type="hidden" name="'
            . $Param{Key}
            . '" value="'
            . $Value . '">'
            . '<input type="Text" name="'
            . $Param{Key}
            . '::Search" size="'
            . $Size
            . '" value="'
            . $Search . '">' . '<br>'
            . $StringOption
            . $StringSelect
            . '<input class="button" type="submit" name="'
            . $Param{Key}
            . '::ButtonSearch" value="'
            . $Self->{LanguageObject}->Translate( "Search" )
            . '">'
            . '&nbsp;'
            . '<input class="button" type="submit" name="'
            . $Param{Key}
            . '::ButtonClear" value="'
            . $Self->{LanguageObject}->Translate( "Clear" )
            . '">';
    }

    return $String;
}

=item SearchFormDataGet()

get search form data

    my $Value = $BackendObject->SearchFormDataGet(
        Key => 'Item::1::Node::3',
        Item => $ItemRef,
    );

=cut

sub SearchFormDataGet {
    my ( $Self, %Param ) = @_;

    #check needed stuff
    if ( !$Param{Key} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need Key!'
        );
        return;
    }

    # get form data
    my $Value;
    if ( $Param{Value} ) {
        $Value = $Param{Value};
    }
    else {
        $Value = $Self->{ParamObject}->GetParam( Param => $Param{Key} );
    }

    return $Value;
}

=item SearchInputCreate()

create a search input string

    my $Value = $BackendObject->SearchInputCreate(
        Key => 'Item::1::Node::3',
    );

=cut

sub SearchInputCreate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Argument (qw(Key Item)) {
        if ( !$Param{$Argument} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Argument!",
            );
            return;
        }
    }

    # hash with values for the input field
    my %FormData;

    if ( $Param{Value} ) {
        $FormData{Value} = $Param{Value};
    }

    # create input field
    my $InputString = $Self->InputCreate(
        %FormData,
        Key    => $Param{Key},
        Item   => $Param{Item},
        ItemId => $Param{Key},
    );

    return $InputString;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

=cut

=head1 VERSION

$Revision: 1.3 $ $Date: 2016/05/27 13:23:06 $

=cut

