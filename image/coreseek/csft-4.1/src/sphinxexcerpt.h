//
// $Id$
//

//
// Copyright (c) 2001-2011, Andrew Aksyonoff
// Copyright (c) 2008-2011, Sphinx Technologies Inc
// All rights reserved
//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License. You should have
// received a copy of the GPL license along with this program; if you
// did not, you can find it at http://www.gnu.org/
//

#ifndef _sphinxexcerpt_
#define _sphinxexcerpt_

#include "sphinx.h"

/// a query to generate an excerpt
/// everything string is expected to be UTF-8
struct ExcerptQuery_t
{
public:
	CSphString		m_sSource;			///< source text (or file name, see m_bLoadFiles)
	CSphString		m_sWords;			///< words themselves
	CSphString		m_sBeforeMatch;		///< string to insert before each match
	CSphString		m_sAfterMatch;		///< string to insert after each match
	CSphString		m_sChunkSeparator;	///< string to insert between matching chunks (in limited mode only)
	CSphString		m_sStripMode;		///< strip mode
	int				m_iLimit;			///< max chars in snippet (0 if unlimited)
	int				m_iLimitWords;		///< max words in snippet
	int				m_iLimitPassages;	///< max passages in snippet
	int				m_iAround;			///< how much words to highlight around each match
	int				m_iPassageId;		///< current %PASSAGE_ID% counter value (must start at 1)
	int				m_iPassageBoundary;	///< passage boundary mode
	bool			m_bRemoveSpaces;	///< whether to collapse whitespace
	bool			m_bExactPhrase;		///< whether to highlight exact phrase matches only
	bool			m_bUseBoundaries;	///< whether to extract passages by phrase boundaries setup in tokenizer
	bool			m_bWeightOrder;		///< whether to order best passages in document (default) or weight order
	bool			m_bHighlightQuery;	///< whether try to highlight the whole query, or always word-by-word
	bool			m_bForceAllWords;	///< whether to ignore limit until all needed keywords are highlighted (#448)
	bool			m_bLoadFiles;		///< whether to interpret source as text or file name
	bool			m_bAllowEmpty;		///< whether to allow empty snippets (by default, return something from the start)
	bool			m_bEmitZones;		///< whether to emit zone for passage
	int				m_iRawFlags;		///< flags as they received from proto (to avoid coding/decoding to agents)
	CSphString		m_sRawPassageBoundary; ///< boundary as it received from proto (to avoid coding/decoding to agents)

public:
	int64_t			m_iSize;			///< file size, to sort to work-queue order
	int				m_iSeq;				///< request order, to sort back to request order
	int				m_iNext;			///< the next one in one-link list for batch processing
	char *			m_sRes;				///< snippet result holder (NOT owned)
	CSphString		m_sError;			///< snippet error message
	bool			m_bHasBeforePassageMacro;
	bool			m_bHasAfterPassageMacro;
	CSphString		m_sBeforeMatchPassage;
	CSphString		m_sAfterMatchPassage;

public:
	ExcerptQuery_t ();
};

/// an excerpt generator
/// returns a newly allocated string in encoding specified by tokenizer on success
/// returns NULL on failure
char * sphBuildExcerpt ( ExcerptQuery_t &, CSphDict *, ISphTokenizer *, const CSphSchema *, CSphIndex *, CSphString & sError, const CSphHTMLStripper *, ISphTokenizer * );

#endif // _sphinxexcerpt_

//
// $Id$
//
