#include <glib.h>
#include <mkdio.h>
#include <string.h>

void
thief_markdown_to_html (const char *raw_mk, long flags, char **html) {
    MMIOT *document = NULL;
    char *compiled = NULL;

    g_return_if_fail (html != NULL);
    *html = NULL;

    if (raw_mk == NULL) {
        return;
    }

#if THIEF_LIBMARKDOWN3
    mkd_flag_t *flag_blob = mkd_flags ();
    mkd_set_flag_bitmap (flag_blob, flags);

    document = gfm_string (raw_mk, (int) strlen (raw_mk), flag_blob);
    if (document != NULL) {
        mkd_compile (document, flag_blob);
        if (mkd_document (document, &compiled)) {
            *html = g_strdup (compiled);
        }
        mkd_cleanup (document);
    }

    mkd_free_flags (flag_blob);
#else
    document = gfm_string (raw_mk, (int) strlen (raw_mk), (int) flags);
    if (document != NULL) {
        mkd_compile (document, (int) flags);
        if (mkd_document (document, &compiled)) {
            *html = g_strdup (compiled);
        }
        mkd_cleanup (document);
    }
#endif
}
