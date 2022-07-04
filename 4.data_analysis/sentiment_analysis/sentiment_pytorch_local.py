import os
from time import time
import pandas as pd
from numpy.ma.core import mean
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification, pipeline

os.getcwd()

torch.cuda.is_available()

tokenizer = AutoTokenizer.from_pretrained(
    pretrained_model_name_or_path="4.data_analysis/sentiment_analysis/data/model", model_max_length=512)

model = AutoModelForSequenceClassification.from_pretrained(
    pretrained_model_name_or_path="4.data_analysis/sentiment_analysis/data/model")

nlp = pipeline("sentiment-analysis", model=model, tokenizer=tokenizer,
               device=0, padding="longest", truncation=True, max_length=512, top_k=3)

example = """
Odborníci na rostlinnou stravu se jí snaží nahrazovat živočišné produkty, na které jsme jako populace zvyklí. V rámci těchto snah vznikají různé typy masa, které by konzument nerozeznal od toho z řeznictví. S výzvou imitovat tímto způsobem i texturu mořských plodů si poradili dánští vědci, píše The Guardian.

Pokusy o výrobu rostlinné alternativy masa mořských živočichů vždy pokulhávaly daleko za náhražkami mléka nebo hovězího masa. Příčiny můžeme hledat v menší poptávce nebo mylném předpokladu, že jsou mořské plody udržitelnější variantou konzumace živočišných produktů. Dalším důvodem je jejich textura, která je měkká, ale zároveň při žvýkání klade odpor, což je poměrně složité replikovat. Aby se přiblížili vláknité struktuře mušlí a korýšů, kvasí kodaňští vědci mořské řasy na podkladu z podhoubí. Díky tomu dosáhnou jak propletené struktury, tak chuti oceánu, kterou se tyto dobroty vyznačují. Navíc jsou mořské řasy nutričně hodnotné.

Ve snaze dosáhnout výsledku, po kterém lidé sáhnou nejen z ekologických a etických, ale také kulinářských důvodů, se vědci spojili se s restaurací Alchemist, která má dvě michelinské hvězdy. Rasmus Munk, šéfkuchař a spolumajitel podniku, uvedl, že chce změnit vnímání nových potravin. „Upřímně řečeno, na trhu jsem momentálně nenašel nic, co bych zařadil na jídelní lístek,“ vysvětluje své motivy pro spolupráci na vývoji rostlinných plodů moře. „My vědci nerozumíme tomu, jak věci udělat chutné, což rozhoduje o tom, zda je lidé budou jíst. Můžeme se toho od sebe hodně naučit. Spolupráce s kuchaři se pomalu objevuje, ale zatím k ní nedošlo v takové míře, jaká by byla potřeba, aby na konci byly opravdu dobré výrobky,“ dodává Dr. Leonie Jahn, mikrobioložka, která projekt vede.
Vědci zjistili, že materiál běžně užívaný pro výrobu solárních panelů se při poškození sám opraví. Předpokládá se, že by tato schopnost mohla být zásadním faktorem pro budoucnost čisté energie.

Specifická látka, která se nazývá selenid antimonu, je tím, co je známé jako solární absorpční materiál. To znamená, že může být použita k využití solární energie, konkrétně přeměně této energie na elektřinu.

Tým z univerzity v Yorku, kterému se tento objev podařil, v současné době zjišťuje, jak by technologie mohla být využita k vytváření solárních panelů s delší životností, které by se mohly při poškození potenciálně samy „zahojit“.

Jednou z největších překážek pokroku u této technologie je její spolehlivost a životnost jednotlivých článků. V současné době mají solární panely průměrnou životnost 25–30 let, takže vývoj technologie, která se dokáže sama opravit, by mohl být zásadním průlomem.

„Proces, kterým se tento polovodivý materiál samoléčí, je podobný tomu, který u mloků umožňuje opětovné dorůstání končetin,“ vyjádřil se vedoucí výzkumu profesor Keith McKenna.

Jaká je budoucnost solární energie?
Výzkumníci ze společnosti GlobalData věří, že klíčem k úplnému přechodu na zelenou energii by mohla být vesmírná solární energie. Využití této energie zahrnuje použití zrcadlových reflektorů, které jsou umístěny na satelitech pohybujících se po oběžné dráze Země. Tyto reflektory by soustředily sluneční energii na solární panely, což by umožnilo využití energie mimo denní světlo.

"""

example = example.lower() \
    .replace(r"[^ěščřžýáíéóúůďťňa-z\.\?\! ]", " ") \
    .replace(r"\.{2,}", ".") \
    .strip() \
    .replace(r"  +", " ") \

example = ' '.join(example.split())

start = time()
ner_results = nlp(example)
print(f'Time taken to run: {time() - start} seconds')

df = pd.DataFrame(ner_results)
# arrange the dataframe by column values
df.sort_values("score", ascending=False, inplace=True)
print(df)

print(mean(df["score"]))
