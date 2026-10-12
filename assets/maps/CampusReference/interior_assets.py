"""Original procedural interior kit. Executed by build_run_interiors.py.
All inputs are local metres relative to the current room's floor origin.
"""
def chair(x,y,z=0,angle=0):
    box('Furniture',(x,y,z+.48),(.62,.64,.1),SEAT,angle)
    box('Furniture',(x,y+.28,z+.88),(.62,.12,.7),SEAT,angle)
    for dx in [-.25,.25]:
        for dy in [-.25,.25]:box('Furniture',(x+dx,y+dy,z+.24),(.045,.045,.48),STEEL)
def desk(x,y,z=0):
    box('Furniture',(x,y,z+.79),(2,.9,.1),IVORY)
    for dx in [-.8,.8]:box('Furniture',(x+dx,y,z+.4),(.06,.75,.8),STEEL)
    box('Electronics',(x,y+.2,z+1.14),(.75,.08,.46),STEEL)
    box('Electronics',(x,y+.151,z+1.14),(.67,.015,.36),CYAN)
    cylinder('Electronics',(x,y+.2,z+.9),.045,.22,STEEL)
    box('Electronics',(x,y-.2,z+.85),(.49,.18,.035),BLACK)
    for dx in [-.18,-.09,0,.09,.18]:box('Electronics',(x+dx,y-.2,z+.872),(.035,.11,.007),GRAY)
    box('Electronics',(x+.46,y-.2,z+.87),(.07,.11,.04),BLACK)
    chair(x,y-1,z)
    cylinder('SmallProps',(x-.63,y-.13,z+.89),.06,.14,IVORY)
    box('SmallProps',(x+.67,y,z+.86),(.32,.4,.035),PAPER)
def bench(x,y,z=0,length=3):
    for j in range(5):box('Furniture',(x,y-.3+j*.15,z+.5),(length,.1,.07),WOOD)
    for dx in [-length*.35,length*.35]:box('Furniture',(x+dx,y,z+.23),(.09,.65,.46),STEEL)
    for zz in [.9,1.08]:box('Furniture',(x,y+.3,z+zz),(length,.1,.16),WOOD)
def sofa(x,y,z=0,length=3,m=None):
    m=SEAT if m is None else m
    box('Furniture',(x,y,z+.38),(length,1,.6),m)
    box('Furniture',(x,y+.4,z+.82),(length,.22,.85),m)
    for dx in [-length/2,length/2]:box('Furniture',(x+dx,y,z+.63),(.2,1.1,.6),m)
    for dx in [-length*.35,0,length*.35]:box('Furniture',(x+dx,y-.13,z+.71),(.5,.7,.04),m)
def coffee_table(x,y,z=0):
    box('Furniture',(x,y,z+.52),(1.3,1.2,.08),WOOD)
    for dx in [-.45,.45]:
        for dy in [-.4,.4]:box('Furniture',(x+dx,y+dy,z+.25),(.04,.04,.5),STEEL)
    cylinder('SmallProps',(x+.3,y,z+.62),.06,.14,IVORY)
    box('SmallProps',(x-.3,y,z+.58),(.35,.4,.035),PAPER)
def low_partition(x,y,w=5,h=1.2,angle=0):
    box('Cover',(x,y,h/2),(w,.18,h),PANEL,angle)
    box('Cover',(x,y,h+.025),(w+.05,.23,.05),STEEL,angle)
    for dx in [-w/2+.3,w/2-.3]:box('Cover',(x+dx,y,.08),(.45,.7,.16),STEEL)
def screen(x,y,z=1.5,w=2,h=1):
    box('Electronics',(x,y,z),(w,.12,h),STEEL)
    box('Electronics',(x,y-.075,z),(w-.13,.015,h-.13),CYAN)
    for j in range(5):box('ScreenGraphics',(x-w*.35+j*w*.14,y-.09,z-.1),(w*.08,.008,.16+j*.035),MINT)
def lockers(x,y,count=4,z=0):
    for j in range(count):
        xx=x+(j-(count-1)/2)*.7
        box('Storage',(xx,y,z+1.02),(.67,.7,2.04),PANEL)
        box('Storage',(xx,y-.365,z+1.05),(.59,.03,1.91),GRAY)
        box('Storage',(xx+.18,y-.39,z+1.2),(.055,.03,.1),CHROME)
        for zz in [1.6,1.7,1.8]:box('Storage',(xx,y-.39,z+zz),(.35,.02,.026),BLACK)
        box('Storage',(xx,y-.402,z+1.9),(.13,.012,.06),PAPER)
def bookshelf(x,y,count=2,z=0,metal=False):
    w=count*1.2
    m=STEEL if metal else WOOD
    box('Storage',(x,y+.35,z+1.1),(w,.08,2.2),m)
    for dx in [-w/2,w/2]:box('Storage',(x+dx,y,z+1.1),(.08,.8,2.2),m)
    for zz in [.1,.6,1.1,1.6,2.1]:
        box('Storage',(x,y,z+zz),(w,.85,.07),m)
        for j in range(int(w/.17)-1):
            xx=x-w/2+.17+j*.17
            box('SmallProps',(xx,y-.04,z+zz+.21),(.12,.4,.36),R.choice([BLUE,RED,TAN,PAPER,TEAL]))
def crate(x,y,z=0,w=1.2):
    box('Cover',(x,y,z+w/2),(w,w,w),TAN)
    for dx in [-w*.35,w*.35]:box('SmallProps',(x+dx,y-w/2-.015,z+w/2),(.07,.035,w-.06),IVORY)
    box('SmallProps',(x,y-w/2-.04,z+w*.68),(.27,.015,.17),PAPER)
def supply_barrel(x,y,z=0,accent=None):
    global forced
    prev=forced;forced='Breakable_'+str(len(breakables)+1)
    accent=ORANGE if accent is None else accent
    cylinder('Breakable',(x,y,z+.47),.32,.94,accent,20)
    for zz in [.06,.24,.7,.9]:torus('Breakable',(x,y,z+zz),.325,.026,STEEL)
    cylinder('Breakable',(x+.12,y,z+.965),.05,.025,BLACK,10)
    breakables.append({'id':forced,'building':current_building,'position_m':world((x,y,z)),'implemented':False,'role':'destructible_supply_prop'})
    forced=prev
def rack(x,y,w=4,h=2.7,depth=1.4,z=0,loaded=True):
    for dx in [-w/2,w/2]:
        for dy in [-depth/2,depth/2]:box('CargoRacks',(x+dx,y+dy,z+h/2),(.12,.12,h),ORANGE)
    for zz in [.15,h*.42,h*.8]:
        box('CargoRacks',(x,y,z+zz),(w,depth,.12),STEEL)
        if loaded:
            for j in range(max(1,int(w/1.2))):
                xx=x-w/2+.65+j*1.2;crate(xx,y,z+zz+.1,.85)
    for dy in [-depth/2,depth/2]:beam('CargoRacks',(x-w/2,y+dy,z+.2),(x+w/2,y+dy,z+h-.1),.06,.06,STEEL)
def server(x,y,z=0):
    box('Servers',(x,y,z+1.2),(.85,.9,2.4),BLACK)
    for dx in [-.4,.4]:box('Servers',(x+dx,y-.46,z+1.2),(.055,.08,2.4),CHROME)
    for j in range(11):
        zz=z+.16+j*.2
        box('Servers',(x,y-.465,zz),(.73,.035,.16),STEEL)
        for dx in [-.23,-.12,0,.12]:box('Servers',(x+dx,y-.49,zz),(.055,.008,.035),BLACK)
        for dx in [.25,.32]:box('Servers',(x+dx,y-.497,zz),(.025,.012,.025),MINT)
    box('Servers',(x,y,z+2.45),(.9,.95,.08),PANEL)
def labbench(x,y,w=3,z=0):
    box('Lab',(x,y,z+.42),(w,.95,.84),IVORY)
    box('Lab',(x,y,z+.92),(w+.12,1.05,.12),CHROME)
    for j in range(max(1,int(w/.65))):
        xx=x-w/2+.35+j*.65
        box('Lab',(xx,y-.49,z+.45),(.53,.04,.65),PANEL)
        box('Lab',(xx,y-.52,z+.64),(.23,.04,.025),STEEL)
    for dx in [-.65,0,.65]:
        cylinder('LabGlass',(x+dx,y-.1,z+1.07),.055,.23,GLASS,12)
        cylinder('LabGlass',(x+dx,y-.1,z+1.22),.04,.07,CYAN,10)
    box('Lab',(x+w*.32,y+.15,z+1.23),(.4,.5,.45),STEEL)
    box('Lab',(x+w*.32,y-.11,z+1.23),(.23,.02,.16),MINT)
def specimen(x,y,z=0,h=2.6):
    cylinder('LabPods',(x,y,z+.16),.78,.32,STEEL,24)
    cylinder('LabGlass',(x,y,z+h/2),.64,h-.38,GLASS,24)
    for a in [0,math.pi/2,math.pi,math.pi*1.5]:
        rod('LabPods',(x+math.cos(a)*.68,y+math.sin(a)*.68,z+.2),(x+math.cos(a)*.68,y+math.sin(a)*.68,z+h-.1),.045,CHROME)
    cylinder('LabPods',(x,y,z+h),.77,.2,STEEL,24)
    torus('LabPods',(x,y,z+.36),.69,.03,MINT);torus('LabPods',(x,y,z+h-.19),.68,.035,CYAN)
    sphere('LabSample',(x,y,z+h*.55),.3,MINT,(.7,1,1.65),12,8)
    box('LabPods',(x,y-.82,z+.85),(.38,.15,.55),STEEL)
    box('LabPods',(x,y-.91,z+1.0),(.25,.01,.12),CYAN)
def microscope(x,y,z=0):
    box('Lab',(x,y,z+.05),(.35,.3,.1),IVORY)
    rod('Lab',(x,y+.08,z+.08),(x,y+.08,z+.44),.05,STEEL)
    rod('Lab',(x,y+.08,z+.44),(x,y-.13,z+.58),.055,STEEL)
    cylinder('Lab',(x,y-.07,z+.22),.035,.1,BLACK)
    box('Lab',(x,y,z+.21),(.22,.25,.025),STEEL)
def medical_bed(x,y,z=0):
    box('Medical',(x,y,z+.68),(1.02,2.2,.18),IVORY)
    box('Medical',(x,y,z+.42),(.9,1.8,.12),STEEL)
    box('Medical',(x,y+.66,z+.83),(.8,.47,.13),PAPER)
    box('Medical',(x,y-.31,z+.8),(.88,1.2,.07),TEAL)
    for dx in [-.5,.5]:
        for dy in [-.92,.92]:
            rod('Medical',(x+dx,y+dy,z+.14),(x+dx,y+dy,z+.58),.04,CHROME)
            rod('Medical',(x+dx-.045,y+dy,z+.12),(x+dx+.045,y+dy,z+.12),.1,BLACK,10)
        rod('Medical',(x+dx,y-.95,z+.95),(x+dx,y+.95,z+.95),.025,CHROME)
    rod('Medical',(x+.83,y+.53,z+.15),(x+.83,y+.53,z+2),.022,CHROME)
    box('Medical',(x+.9,y+.53,z+1.64),(.15,.06,.25),GLASS)
    box('Medical',(x-.8,y+.55,z+1.18),(.33,.12,.28),STEEL)
    box('Medical',(x-.8,y+.48,z+1.18),(.25,.01,.17),MINT)
def operating_table(x,y,z=0):
    box('Medical',(x,y,z+.88),(1.2,2.4,.16),TEAL)
    box('Medical',(x,y,z+.42),(.75,.7,.84),CHROME)
    rod('Medical',(x-1.1,y,z+.1),(x-1.1,y,z+2.5),.07,CHROME)
    beam('Medical',(x-1.1,y,z+2.5),(x,y,z+2.6),.06,.06,CHROME)
    cylinder('Medical',(x,y,z+2.5),.42,.12,IVORY,20)
    for a in range(6):sphere('Medical',(x+math.cos(a*math.tau/6)*.22,y+math.sin(a*math.tau/6)*.22,z+2.42),.065,WARM,(1,1,.25),8,5)
def rifle(x,y,z=1.4,angle=0):
    box('Armory',(x,y,z),(.1,1.08,.17),BLACK,angle)
    box('Armory',(x,y+.62,z+.04),(.11,.36,.2),WOOD,angle)
    rod('Armory',(x,y-.5,z+.06),(x,y-.98,z+.06),.027,STEEL,10)
    box('Armory',(x,y-.12,z-.2),(.09,.17,.27),STEEL,angle)
    box('Armory',(x,y+.23,z-.14),(.08,.12,.24),BLACK,angle)
    box('Armory',(x,y-.06,z+.17),(.08,.3,.07),STEEL,angle)
def weapon_wall(x,y,w=4,z=0):
    box('Armory',(x,y,z+1.48),(w,.14,2.6),BLACK)
    for j in range(int(w/.4)):
        xx=x-w/2+.2+j*.4
        for zz in [.5,.9,1.3,1.7,2.1,2.5]:box('Armory',(xx,y-.08,z+zz),(.028,.01,.028),STEEL)
    # Rifles displayed vertically: their axes run along Y, rotated into the wall plane.
    for j in range(max(2,int(w/1.1))):
        xx=x-w/2+.65+j*1.1
        box('Armory',(xx,y-.16,z+1.4),(.12,.1,.85),STEEL)
        box('Armory',(xx,y-.16,z+.85),(.17,.12,.35),WOOD)
        rod('Armory',(xx,y-.16,z+1.83),(xx,y-.16,z+2.3),.027,CHROME)
        box('Armory',(xx+.15,y-.16,z+1.1),(.24,.1,.13),BLACK)
def workbench(x,y,w=4,z=0):
    box('Workshop',(x,y,z+.45),(w,.9,.9),STEEL)
    box('Workshop',(x,y,z+.95),(w+.1,1,.1),WOOD)
    for j in range(int(w/.8)):
        xx=x-w/2+.4+j*.8
        box('Workshop',(xx,y-.47,z+.55),(.65,.035,.52),PANEL)
        for zz in [.38,.56,.72]:box('Workshop',(xx,y-.5,z+zz),(.24,.03,.025),CHROME)
    box('Workshop',(x,y+.43,z+1.6),(w,.09,1.2),BLACK)
    for j in range(int(w/.35)):
        xx=x-w/2+.22+j*.35
        rod('Workshop',(xx,y+.35,z+1.3),(xx,y+.35,z+1.8),.024,CHROME,6)
    box('Workshop',(x+w*.3,y-.1,z+1.12),(.38,.3,.24),ORANGE)
    box('Workshop',(x-w*.3,y,z+1.04),(.3,.5,.1),BLACK)
def engine(x,y,z=0):
    box('Workshop',(x,y,z+.6),(1.15,1.2,1.2),STEEL)
    for dx in [-.4,.4]:
        for j in range(4):rod('Workshop',(x+dx,y-.5+j*.3,z+1.2),(x+dx,y-.5+j*.3,z+1.35),.12,CHROME,12)
    for j in range(4):rod('Workshop',(x-.59,y-.45+j*.3,z+.8),(x-.92,y-.45+j*.3,z+.45),.05,CHROME)
    box('Workshop',(x,y,z+.04),(1.5,1.7,.08),BLACK)
def conveyor(x,y,length=5,z=0):
    for dx in [-.58,.58]:box('CargoRacks',(x+dx,y,z+.66),(.12,length,.15),STEEL)
    for dy in [-length*.36,length*.36]:
        for dx in [-.5,.5]:box('CargoRacks',(x+dx,y+dy,z+.3),(.06,.06,.6),STEEL)
    for j in range(int(length/.22)):
        yy=y-length/2+.12+j*.22;rod('CargoRacks',(x-.55,yy,z+.71),(x+.55,yy,z+.71),.07,CHROME,10)
    for dy in [-length*.3,0,length*.3]:crate(x,y+dy,z+.79,.56)
def retail_shelf(x,y,w=4,z=0):
    box('Retail',(x,y+.32,z+.95),(w,.08,1.9),PANEL)
    for dx in [-w/2,w/2]:box('Retail',(x+dx,y,z+.95),(.07,.7,1.9),STEEL)
    for zz in [.15,.65,1.15,1.65]:
        box('Retail',(x,y,z+zz),(w,.75,.065),IVORY)
        for j in range(int(w/.25)-1):
            xx=x-w/2+.22+j*.25
            if j%3:cylinder('SmallProps',(xx,y-.1,z+zz+.16),.075,.26,R.choice([RED,BLUE,ORANGE,TEAL]),10)
            else:box('SmallProps',(xx,y-.06,z+zz+.19),(.18,.26,.32),TAN)
def kitchen(x,y,w=5,z=0):
    labbench(x,y,w,z)
    box('Kitchen',(x-w*.25,y,z+1.06),(.8,.7,.16),BLACK)
    for dx in [-.22,.22]:
        for dy in [-.16,.16]:torus('Kitchen',(x-w*.25+dx,y+dy,z+1.16),.1,.016,CHROME)
    box('Kitchen',(x+w*.27,y,z+1.18),(.8,.45,.5),STEEL)
    box('Kitchen',(x+w*.27,y-.24,z+1.18),(.65,.03,.3),BLACK)
    for dx in [-.16,.16]:cylinder('SmallProps',(x+w*.27+dx,y-.31,z+1.01),.06,.12,IVORY)
def fridge(x,y,z=0):
    box('Retail',(x,y,z+1.1),(1.15,.85,2.2),IVORY)
    box('Retail',(x,y-.44,z+1.15),(.92,.035,1.85),GLASS)
    for zz in [.5,.95,1.4,1.85]:
        box('Retail',(x,y,z+zz),(1.03,.7,.04),STEEL)
        for dx in [-.32,0,.32]:cylinder('SmallProps',(x+dx,y-.15,z+zz+.14),.075,.25,R.choice([TEAL,RED,BLUE]),10)
    rod('Retail',(x+.45,y-.5,z+.75),(x+.45,y-.5,z+1.55),.017,CHROME)
def planter(x,y,z=0):
    box('Furniture',(x,y,z+.28),(.7,.7,.56),PANEL)
    cylinder('Plants',(x,y,z+.59),.29,.07,SOIL)
    rod('Plants',(x,y,z+.6),(x,y,z+1.5),.025,WOOD,6)
    for j in range(6):
        a=j*math.tau/6;sphere('Plants',(x+math.cos(a)*.2,y+math.sin(a)*.2,z+1.04+j*.07),.23,LEAF,(1,.65,.5),8,5)
def control_desk(x,y,z=0,count=3):
    box('Electronics',(x,y,z+.46),(count*1.3,1,.92),PANEL)
    box('Electronics',(x,y-.12,z+.98),(count*1.3,1,.12),STEEL)
    for j in range(count):
        xx=x+(j-(count-1)/2)*1.3
        screen(xx,y+.2,z+1.36,.88,.5)
        box('Electronics',(xx,y-.28,z+1.06),(.45,.14,.035),BLACK)
    chair(x,y-1,z)
def decon_arch(x,y,z=0):
    for dx in [-1.3,1.3]:
        box('Lab',(x+dx,y,z+1.45),(.22,.55,2.9),IVORY)
        box('Lab',(x+dx,y-.3,z+1.45),(.07,.035,2.2),CYAN)
    box('Lab',(x,y,z+2.9),(2.8,.55,.22),PANEL)
    for j in range(6):cylinder('Lab',(x-1+j*.4,y,z+2.74),.035,.08,CHROME,8)
def ceiling_lamp(x,y,z=3.2,length=2.6):
    box('Lighting',(x,y,z),(length,.3,.1),STEEL)
    box('Lighting',(x,y,z-.067),(length-.12,.22,.025),SOFT)
def floor_ring(x,y,r=3,m=None,z=0):
    m=ORANGE if m is None else m
    for j in range(48):
        a=j*math.tau/48;b=(j+1)*math.tau/48
        beam('FloorMarkings',(x+math.cos(a)*r,y+math.sin(a)*r,z+.02),(x+math.cos(b)*r,y+math.sin(b)*r,z+.02),.08,.016,m)
def chest_model(x,y,z=0,accent=None):
    accent=GOLD if accent is None else accent
    box('Activity',(x,y,z+.34),(1.15,.72,.68),BLACK)
    box('Activity',(x,y,z+.7),(1.21,.78,.16),accent)
    for dx in [-.42,.42]:box('Activity',(x+dx,y,z+.42),(.09,.79,.78),STEEL)
    box('Activity',(x,y-.4,z+.47),(.2,.05,.21),accent)
    box('Activity',(x,y-.438,z+.5),(.06,.012,.07),SOFT)
def activity_model(kind,x,y,z=0):
    accent={'LootCache':GOLD,'ChargeRelay':CYAN,'RiskTerminal':PURPLE,'EliteSignal':RED,'RecoveryStation':MINT,'Recycler':ORANGE,'WeaponBench':GOLD,'SampleHunt':MINT,'PurifierDefence':TEAL,'BossBeacon':RED,'TradeStation':BLUE,'DataCache':CYAN}.get(kind,GOLD)
    if kind in ['LootCache','DataCache']:
        chest_model(x,y,z,accent)
        if kind=='DataCache':screen(x,y+.37,z+1.0,.6,.28)
    elif kind=='WeaponBench':
        workbench(x,y,3,z);rifle(x-.5,y,z+1.11)
        box('Activity',(x+.9,y,z+1.3),(.35,.4,.6),STEEL);box('Activity',(x+.9,y-.23,z+1.4),(.22,.025,.22),GOLD)
    elif kind=='RecoveryStation':
        box('Activity',(x,y,z+.95),(.9,.65,1.9),IVORY)
        box('Activity',(x,y-.34,z+1.18),(.65,.035,.47),MINT)
        box('Activity',(x,y-.37,z+1.18),(.08,.014,.35),PAPER);box('Activity',(x,y-.37,z+1.18),(.35,.015,.08),PAPER)
        box('Activity',(x,y-.36,z+.5),(.5,.07,.17),BLACK)
        for dx in [-.32,.32]:cylinder('Activity',(x+dx,y+.4,z+.8),.17,1.1,CHROME,16)
    elif kind=='Recycler':
        box('Activity',(x,y,z+.68),(1.6,1.3,1.36),PANEL)
        box('Activity',(x,y-.67,z+.87),(1.1,.035,.36),BLACK)
        for j in range(6):rod('Activity',(x-.46+j*.18,y-.69,z+.75),(x-.46+j*.18,y-.69,z+1.02),.06,STEEL,8)
        box('Activity',(x,y,z+1.44),(1.7,1.4,.16),ORANGE)
        box('Activity',(x+.55,y-.69,z+.45),(.22,.03,.16),SOFT)
    elif kind in ['ChargeRelay','PurifierDefence']:
        cylinder('Activity',(x,y,z+.15),1,.3,STEEL,24)
        cylinder('Activity',(x,y,z+1.3),.6,2.3,GLASS,24)
        for a in [0,math.pi/2,math.pi,math.pi*1.5]:
            rod('Activity',(x+math.cos(a)*.7,y+math.sin(a)*.7,z+.25),(x+math.cos(a)*.7,y+math.sin(a)*.7,z+2.65),.07,CHROME)
        cylinder('Activity',(x,y,z+2.68),.88,.28,STEEL,24)
        for zz in [.55,1.25,1.95]:torus('Activity',(x,y,z+zz),.65,.035,accent)
        box('Activity',(x,y-.92,z+1.0),(.65,.3,.8),STEEL);screen(x,y-1.09,z+1.2,.45,.27)
    elif kind=='SampleHunt':
        labbench(x,y,2.5,z)
        for dx in [-.65,0,.65]:
            cylinder('Activity',(x+dx,y,z+1.15),.1,.3,GLASS,16);cylinder('Activity',(x+dx,y,z+1.33),.11,.07,MINT,16)
    elif kind=='TradeStation':
        box('Activity',(x,y,z+1.1),(1.25,.8,2.2),BLUE)
        screen(x-.1,y-.42,z+1.45,.75,.65)
        box('Activity',(x,y-.46,z+.45),(.8,.06,.16),BLACK)
        box('Activity',(x+.47,y-.45,z+1.25),(.13,.03,.1),GOLD)
    else:
        cylinder('Activity',(x,y,z+.16),.85,.32,STEEL,24)
        box('Activity',(x,y,z+1.07),(.65,.7,1.8),BLACK)
        screen(x,y-.39,z+1.38,.5,.39)
        for dx in [-.38,.38]:box('Activity',(x+dx,y,z+1.05),(.06,.8,1.5),accent)
        rod('Activity',(x,y,z+1.97),(x,y,z+2.7),.04,CHROME)
        sphere('Activity',(x,y,z+2.7),.12,accent,(1,1,1),12,7)
