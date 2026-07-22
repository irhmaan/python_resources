

from difflib import get_close_matches


class SimilarColumn:
    def getSimilarColumn(self, sourceWord:str, possibilities: list) -> list[str]:
        '''
        This method checks a given word against a list of word and return list of words,that could be similar to original word.
        n = number of record you need per match, n=1 mean give me only single word, default to 3.
        cutoff (default 0.6) is a float in [0, 1]
        '''
        # Find the closest match (n=1 returns top 1 result, cutoff=0.6 is the threshold)
        return get_close_matches(sourceWord, possibilities, n=1, cutoff=0.6) 

    def getSimilarColumnSQL(self):
        #TODO: not sure, but we can require a separate similar funnctionality for sql
        #TODO: But If we can reduce and get sql columns name and its datatype similar to excel then no need.
        pass
    