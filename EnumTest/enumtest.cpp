#include <QString>
#include <QtTest>

#include "../Enums.hpp"


class EnumTest : public QObject
{
    Q_OBJECT

public:
    EnumTest();

private Q_SLOTS:
    void testColor1();
    void testColor2();
    void testColor3();
    void testColor4();
    void testColor5();
    void testCurrency();
    void testCountry();
};

EnumTest::EnumTest()
{
}

void EnumTest::testColor1()
{
    // Color1()
    Color1 c1;
    QCOMPARE(c1.isValid(), false);
    QVERIFY(c1 == Color1::Invalid);
    QCOMPARE(c1.toString(), "Invalid");

    // Color1(Value val)
    c1 = Color1(Color1::Red);
    QCOMPARE(c1.isValid(), true);
    QVERIFY(c1 == Color1::Red);
    QCOMPARE(c1.toString(), "Red");

    // Color1(const Color1 &other)
    c1 = Color1(Color1(Color1::Green));
    QCOMPARE(c1.toString(), "Green");

    // Color1(int val)
    QCOMPARE(Color1(Color1::Green).toInt(), c1.toInt());

    // Color1(const char * val)
    QCOMPARE(Color1("Green").toInt(), c1.toInt());

    c1 = Color1::Blue; // operator =(Value val)
    QVERIFY(c1 == Color1::Blue); // operator ==(Value val)

    c1 = Color1("Blue"); // operator =(Value val)
    QVERIFY(c1 == Color1("Blue")); // operator =(const Color1 &other)

    // isValid()
    QVERIFY(c1.isValid());

    // fromInt(int val), toInt()
    QVERIFY(Color1::fromInt(int(Color1::White)).toInt() == int(Color1::White));
    QVERIFY(Color1::fromInt(int(Color1::Invalid)).toInt() == int(Color1::Invalid));

    // fromString(const char * val), toString()
    QCOMPARE(Color1::fromString("Black").toString(), "Black");

    // enumName()
    QCOMPARE(Color1::enumName(), "Color1");
}


void EnumTest::testColor2()
{
    // Color2()
    Color2 c1;
    QCOMPARE(c1.isValid(), false);
    QVERIFY(c1 == Color2::Invalid);
    QCOMPARE(c1.toInt(), -1);
    QCOMPARE(c1.toString(), "Invalid");

    // Color2(Value val)
    c1 = Color2(Color2::Red);
    QCOMPARE(c1.isValid(), true);
    QVERIFY(c1 == Color2::Red);
    QCOMPARE(c1.toInt(), 0xFF0000);
    QCOMPARE(c1.toString(), "Red");

    // Color2(const Color2 &other)
    c1 = Color2(Color2(Color2::Green));
    QCOMPARE(c1.toInt(), 0x00FF00);
    QCOMPARE(c1.toString(), "Green");

    // Color2(int val)
    QCOMPARE(Color2(Color2::Green).toInt(), c1.toInt());

    // Color2(const char * val)
    QCOMPARE(Color2("Green").toInt(), c1.toInt());

    c1 = Color2::Blue; // operator =(Value val)
    QVERIFY(c1 == Color2::Blue); // operator ==(Value val)

    c1 = Color2("Blue"); // operator =(Value val)
    QVERIFY(c1 == Color2("Blue")); // operator =(const Color2 &other)
    QCOMPARE(c1.toInt(), 0x0000FF);

    // isValid()
    QVERIFY(c1.isValid());

    // fromInt(int val), toInt()
    QVERIFY(Color2::fromInt(0xFFFFFF).toInt() == 0xFFFFFF);
    QVERIFY(Color2::fromInt(-1).toInt() == -1);

    // fromString(const char * val), toString()
    QCOMPARE(Color2::fromString("Black").toString(), "Black");

    // enumName()
    QCOMPARE(Color2::enumName(), "Color2");
}


void EnumTest::testColor3()
{
    // Color3()
    Color3 c3;
    QCOMPARE(c3.isValid(), false);
    QVERIFY(c3 == Color3::Invalid);
    QCOMPARE(c3.toInt(), -1);
    QCOMPARE(c3.toString(), "Invalid");

    // Color3(Value val)
    c3 = Color3(Color3::Red);
    QCOMPARE(c3.isValid(), true);
    QVERIFY(c3 == Color3::Red);
    QCOMPARE(c3.toInt(), 0xFF0000);
    QCOMPARE(c3.toString(), "Red");

    // Color3(const Color3 &other)
    c3 = Color3(Color3(Color3::Green));
    QCOMPARE(c3.toInt(), 0x00FF00);
    QCOMPARE(c3.toString(), "Green");

    // Color3(int val)
    QCOMPARE(Color3(Color3::Green).toInt(), c3.toInt());

    // Color3(const char * val)
    QCOMPARE(Color3("Green").toInt(), c3.toInt());

    c3 = Color3::Blue; // operator =(Value val)
    QVERIFY(c3 == Color3::Blue); // operator ==(Value val)

    c3 = Color3("Blue"); // operator =(const Color3 &other)
    QVERIFY(c3 == Color3("Blue")); // operator ==(const Color3 &other)
    QCOMPARE(c3.toInt(), 0x0000FF);

    // isValid()
    QVERIFY(c3.isValid());

    // fromInt(int val), toInt()
    QVERIFY(Color3::fromInt(0xFFFFFF).toInt() == 0xFFFFFF);
    QVERIFY(Color3::fromInt(-1).toInt() == -1);

    // fromString(const char * val), toString()
    QCOMPARE(Color3::fromString("Black").toString(), "Black");

    // enumName()
    QCOMPARE(Color3::enumName(), "Color3");
}


void EnumTest::testColor4()
{
    // Color4()
    Color4 c1;
    QCOMPARE(c1.isValid(), false);
    QVERIFY(c1 == Color4::Invalid);
    QCOMPARE(c1.toString(), "Invalid");

    // Color4(Value val)
    c1 = Color4(Color4::Red);
    QCOMPARE(c1.isValid(), true);
    QVERIFY(c1 == Color4::Red);
    QCOMPARE(c1.toString(), "Red");

    // Color4(const Color4 &other)
    c1 = Color4(Color4(Color4::Green));
    QCOMPARE(c1.toString(), "Green");

    // Color4(int val)
    QCOMPARE(Color4(Color4::Green).toInt(), c1.toInt());

    // Color4(const char * val)
    QCOMPARE(Color4("Green").toInt(), c1.toInt());

    c1 = Color4::Blue; // operator =(Value val)
    QVERIFY(c1 == Color4::Blue); // operator ==(Value val)

    c1 = Color4("Blue"); // operator =(Value val)
    QVERIFY(c1 == Color4("Blue")); // operator =(const Color4 &other)

    // isValid()
    QVERIFY(c1.isValid());

    // fromInt(int val), toInt()
    QVERIFY(Color4::fromInt(int(Color4::White)).toInt() == int(Color4::White));
    QVERIFY(Color4::fromInt(int(Color4::Invalid)).toInt() == int(Color4::Invalid));

    // fromString(const char * val), toString()
    QCOMPARE(Color4::fromString("Black").toString(), "Black");

    // enumName()
    QCOMPARE(Color4::enumName(), "Color4");
}


void EnumTest::testColor5()
{
    // Color5()
    Color5 c1;
    QCOMPARE(c1.isValid(), false);
    QVERIFY(c1 == Color5::Null);
    QCOMPARE(c1.toInt(), -100);
    QCOMPARE(c1.toString(), "Null");

    // Color5(Value val)
    c1 = Color5(Color5::Red);
    QCOMPARE(c1.isValid(), true);
    QVERIFY(c1 == Color5::Red);
    QCOMPARE(c1.toInt(), 0xFF0000);
    QCOMPARE(c1.toString(), "Red");

    // Color5(const Color5 &other)
    c1 = Color5(Color5(Color5::Green));
    QCOMPARE(c1.toInt(), 0x00FF00);
    QCOMPARE(c1.toString(), "Green");

    // Color5(int val)
    QCOMPARE(Color5(Color5::Green).toInt(), c1.toInt());

    // Color5(const char * val)
    QCOMPARE(Color5("Green").toInt(), c1.toInt());

    c1 = Color5::Blue; // operator =(Value val)
    QVERIFY(c1 == Color5::Blue); // operator ==(Value val)

    c1 = Color5("Blue"); // operator =(Value val)
    QVERIFY(c1 == Color5("Blue")); // operator =(const Color5 &other)
    QCOMPARE(c1.toInt(), 0x0000FF);

    // isValid()
    QVERIFY(c1.isValid());

    // fromInt(int val), toInt()
    QVERIFY(Color5::fromInt(0xFF0000).toInt() == 0xFF0000);
    QVERIFY(Color5::fromInt(0).toInt() == 0);

    // fromString(const char * val), toString()
    QCOMPARE(Color5::fromString("Black").toString(), "Black");

    // enumName()
    QCOMPARE(Color5::enumName(), "Color5");
}


void EnumTest::testCurrency()
{
    // Currency()
    Currency c1;
    QCOMPARE(c1.isValid(), false);
    QVERIFY(c1 == Currency::Invalid);

    // Currency(Value val)
    c1 = Currency(Currency::UAH);
    QCOMPARE(c1.isValid(), true);
    QVERIFY(c1 == Currency::UAH);
    QCOMPARE(c1.toString(), "UAH");

    QCOMPARE(c1.toISO4217Name(), "Hryvnia");
    QCOMPARE(Currency(Currency::EUR).toISO4217Name2(), "Euro");
    QCOMPARE(Currency(Currency::USD).toISO4217Number(), 840);

    // Enumeration values
    QStringList codes;
    for (int i = 0;i < Currency::ValueCount;i++)
    {
        c1 = Currency::Value(i); // this is hack, it is safe only in current environment
        if (c1.isValid())
        {
            QString s = QString("%1(%2)").arg(c1.toString()).arg(c1.toISO4217Number());
            codes.append(s);
        }
    }
    qDebug() << codes.join(", ");

    // enumName()
    QCOMPARE(Currency::enumName(), "Currency");
}


void EnumTest::testCountry()
{
    // Country()
    Country c1;
    QCOMPARE(c1.isValid(), false);
    QVERIFY(c1 == Country::Invalid);

    // Country(Value val)
    c1 = Country(Country::Russia);
    QCOMPARE(c1.isValid(), true);
    QVERIFY(c1 == Country::Russia);
    QCOMPARE(c1.toString(), "Russia");

    QCOMPARE(c1.toCurrency1(), Currency(Currency::RUB));
    QCOMPARE(c1.toJustInt(), 123);
    QCOMPARE(c1.toJustShort(), short(321));

    // enumName()
    QCOMPARE(Country::enumName(), "Country");
}


QTEST_APPLESS_MAIN(EnumTest)

#include "enumtest.moc"
